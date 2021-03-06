resource "oci_core_volume" "bv" {
    count = length(var.bv_device_paths_to_add)
    #Required
    availability_domain = var.ad
    compartment_id = var.compartment_ocid
    #Optional
    display_name = "add_bv_${count.index + 1}"
    size_in_gbs = var.bv_storage_gb
    vpus_per_gb = var.vpus_per_gb
}

resource "oci_core_volume_attachment" "bv_attachment" {
    count = length(var.bv_device_paths_to_add) * length(data.oci_core_instances.storage_nodes.instances)
    #Required
    attachment_type = "iscsi"
    instance_id = data.oci_core_instances.storage_nodes.instances[floor(count.index / length(var.bv_device_paths_to_add))].id
    volume_id = oci_core_volume.bv[count.index % length(var.bv_device_paths_to_add)].id

    #Optional
    display_name = "add_bv_attachment${count.index + 1}"
    is_read_only = false
    is_shareable = true
    device = var.bv_device_paths_to_add[count.index % length(var.bv_device_paths_to_add)]
}

data "oci_core_instances" "storage_nodes" {
    #Required
    compartment_id = var.compartment_ocid
    filter {
      name = "display_name"
      values = [var.storage_server_name_regex_to_match]
      regex = true
    }
}

output "ssh_into_bastion" {
    value = "ssh ${var.user_bastion}@${var.public_ip_bastion}"
}

output "ssh_into_storage_servers" {
    value = null_resource.storage_nodes.*.triggers.key_1
}

resource "null_resource" "storage_nodes" {
    count = length(data.oci_core_instances.storage_nodes.instances)
    triggers = {
      "key_1" = "${data.oci_core_instance.storage_node[count.index].display_name}: ssh ${data.oci_core_instance.storage_node[count.index].private_ip}" 
    }
}

resource "null_resource" "execute_iscsi_commands" {
  depends_on = [null_resource.make_iscsi_files]

  provisioner "file" {
    content     = format("%s\n", var.ssh_private_key_storage_nodes) # newline or formatting will be off
    destination = "/home/opc/.ssh/nodes.key"
    connection {
      host        = var.public_ip_bastion
      type        = "ssh"
      user        = "opc"
      private_key = var.ssh_private_key_bastion
    }
  }

  provisioner "file" {
    source        = "${path.root}/ansible"
    destination   = "/home/opc/"
    connection {
      host        = var.public_ip_bastion
      type        = "ssh"
      user        = "opc"
      private_key = var.ssh_private_key_bastion
    }
  }

  # copy playbooks folder to bastion
  provisioner "file" {
    source        = "${path.root}/playbooks"
    destination   = "/home/opc/"
    connection {
      host        = var.public_ip_bastion
      type        = "ssh"
      user        = "opc"
      private_key = var.ssh_private_key_bastion
    }
  }

  # copy inventory file to bastion into playbooks folder
  provisioner "file" {
    content = templatefile("${path.root}/inventory.tpl", {  
    storage_nodes = data.oci_core_instance.storage_node.*.private_ip
    })
    destination   = "/home/opc/playbooks/inventory"
    connection {
      host        = var.public_ip_bastion
      type        = "ssh"
      user        = "opc"
      private_key = var.ssh_private_key_bastion
    }
  }

  # make hosts file on bastion so can check for when ssh is available on storage nodes
  provisioner "file" {
    content     = join("\n", data.oci_core_instance.storage_node.*.private_ip)
    destination = "/tmp/hosts"
    connection {
      host        = var.public_ip_bastion
      type        = "ssh"
      user        = "opc"
      private_key = var.ssh_private_key_bastion
    }
  }

  # copy configure.sh to bastion
  provisioner "file" {
    source      = "${path.root}/configure.sh"
    destination = "/tmp/configure.sh"
    connection {
      host        = var.public_ip_bastion
      type        = "ssh"
      user        = "opc"
      private_key = var.ssh_private_key_bastion
    }
  }

  # run configure.sh on bastion, which will invoke the Ansible
  provisioner "remote-exec" {
    inline = [
      "chmod 600 /home/opc/.ssh/nodes.key", # set protective permissions or key won't be used
      "chmod a+x /tmp/configure.sh",
      "/tmp/configure.sh"
    ]
    connection {
      host        = var.public_ip_bastion
      type        = "ssh"
      user        = "opc"
      private_key = var.ssh_private_key_bastion
    }
  }
}

data "oci_core_instance" "storage_node" {
    count = length(data.oci_core_instances.storage_nodes.instances)
    #Required
    instance_id = data.oci_core_instances.storage_nodes.instances[count.index].id
}

resource "null_resource" "make_iscsi_files" {
    depends_on = [oci_core_volume_attachment.bv_attachment]
    count = length(var.bv_device_paths_to_add) * length(data.oci_core_instances.storage_nodes.instances) 
    #Required
    

    provisioner "remote-exec" {
      inline = [
        "touch /home/opc/iscsi_commands_${data.oci_core_instance.storage_node[floor(count.index / length(var.bv_device_paths_to_add))].private_ip}.sh",
        "chmod 755 /home/opc/iscsi_commands_${data.oci_core_instance.storage_node[floor(count.index / length(var.bv_device_paths_to_add))].private_ip}.sh",
        "iscsi_command_str=$(cat <<- EOF",
        "# iscsi commands for block volume attachment ${oci_core_volume_attachment.bv_attachment[count.index].display_name}, block volume ${oci_core_volume.bv[count.index % length(var.bv_device_paths_to_add)].display_name}, private ip ${data.oci_core_instance.storage_node[floor(count.index / length(var.bv_device_paths_to_add))].private_ip}, device ${oci_core_volume_attachment.bv_attachment[count.index].device}",
        "sudo iscsiadm -m node -o new -T ${oci_core_volume_attachment.bv_attachment[count.index].iqn} -p ${oci_core_volume_attachment.bv_attachment[count.index].ipv4}:${oci_core_volume_attachment.bv_attachment[count.index].port}",
        "sudo iscsiadm -m node -o update -T ${oci_core_volume_attachment.bv_attachment[count.index].iqn} -n node.startup -v automatic",
        "sudo iscsiadm -m node -T ${oci_core_volume_attachment.bv_attachment[count.index].iqn} -p ${oci_core_volume_attachment.bv_attachment[count.index].ipv4}:${oci_core_volume_attachment.bv_attachment[count.index].port} -l",
        "EOF",
        ")",
        "echo \"$${iscsi_command_str}\" >> /home/opc/iscsi_commands_${data.oci_core_instance.storage_node[floor(count.index / length(var.bv_device_paths_to_add))].private_ip}.sh",
      ]
      connection {
        host        = var.public_ip_bastion
        type        = "ssh"
        user        = var.user_bastion
        private_key = var.ssh_private_key_bastion
      }
    }
}

# indexing example: given 4 block volumes to add and 2 storage servers:
# <oci_core_volume_attachment.bv_attachment index> <data.oci_core_instances.storage_nodes.instances index>,<oci_core_volume.bv index>
# 0 0,0
# 1 0,1
# 2 0,2
# 3 0,3
# 4 1,0
# 5 1,1
# 6 1,2
# 7 1,3
