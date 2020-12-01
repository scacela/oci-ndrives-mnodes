# oci-ndrives-mnodes

Attach n drives to m nodes.

- Provisions a Block Volume for each device path specified (n)
- Attaches each Block Volume at the ISCSI level to the (m) Compute Instances whose display names match a regular expression

Prerequisites:
- 1 bastion node
- 1 pair of SSH keys that can be used to access the bastion node
- The nodes to which the Block Volumes will be attached are are SSH-accessible from the bastion node
- 1 pair of SSH keys that can be used to access all non-bastion nodes (may be the same SSH key pair as previous)
- The display names of the non-bastion nodes can be collectively referenced in your compartment using a regular expression

Usage instructions:
- Get the project:
<pre>
git clone https://github.com/scacela/oci-ndrives-mnodes.git
</pre>
- Update the variables in vars.tf with your values
- Create a file with extension .sh in the same directory as vars.tf and populate it with TF\_VAR\_ environment variables assigned with your values, as in this template, for example:
<pre>
export TF_VAR_compartment_ocid=&ltocid of compartment where non-bastion nodes exist and where Block Volume(s) will be deployed&gt
export TF_VAR_region=&ltregion identifier of region where Terraform actions will be implemented&gt
export TF_VAR_ssh_private_key_bastion=$(cat &ltbastion node private ssh key&gt)
export TF_VAR_ssh_private_key_non_bastion=$(cat &ltnon-bastion node private ssh key&gt)
export TF_VAR_public_ip_bastion="&ltbastion node public ip address&gt"
</pre>
- Deploy the project:
<pre>
source &ltpath to your environment variables file&gt  # save your environment variables to the environment in your CLI instance:
terraform init                                    # initialize Terraform in the same directory as vars.tf
terraform plan                                    # show the deployment plan before applying
terraform apply                                   # apply the deployment plan, enter 'yes' when prompted
</pre>
- Access your nodes once they have been attached, then verify the ISCSI-level Block Volume attachment(s) on the non-bastion nodes:
<pre>
sudo iscsiadm -m node                             # list the ISCSI nodes
</pre>
