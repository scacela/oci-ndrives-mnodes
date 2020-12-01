# oci-ndrives-mnodes

Prerequisites:
- 1 bastion node
- an SSH key pair that can be used to access the bastion node
- nodes that are ssh accessible from the bastion node
- an SSH key pair that can be used to access the non-bastio node (may be the same SSH key pair as previous)
- names of the non-bastion nodes can be singled out from other nodes in your compartment using regex
Identify 1 bastion node and a number of other nodes that can be sshed into from the bastion.

Usage instructions:
<pre>
git clone https://github.com/scacela/oci-ndrives-mnodes.git # get the project
</pre>
- edit vars.tf with your variables
- create a file for your environment variables with extension .sh in the same directory as vars.tf and populate it with TF\_VAR\_ variables. For example:
<pre>
export TF_VAR_compartment_ocid=&ltocid of compartment where non-bastion nodes exist and where block volume(s) will be deployed&gt
export TF_VAR_region=&ltregion identifier of region where Terraform actions will be implemented&gt
export TF_VAR_ssh_private_key_bastion=$(cat &ltbastion node private ssh key&gt)
export TF_VAR_ssh_private_key_non_bastion=$(cat &ltnon-bastion node private ssh key&gt)
export TF_VAR_public_ip_bastion="&ltbastion node public ip address&gt"
</pre>
- for deploying the project, run the following commands:
<pre>
source &ltpath to your environment variables file&gt # save your environment variables to the environment in your CLI instance:
terraform init # initialize Terraform in the same directory as vars.tf
terraform plan # show the deployment plan before applying
terraform apply # apply the deployment plan, enter 'yes' when prompted
</pre>
- access your nodes once they have been attached. Verify the attachment on the nodes:
<pre>
sudo iscsiadm -m node # list the ISCSI nodes
</pre>
