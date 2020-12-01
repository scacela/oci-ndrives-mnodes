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
export TF\_VAR\_compartment\_ocid=<compartment ocid where non-bastion nodes exist and where block volume(s) will be deployed>
export TF\_VAR\_region=<region identifier of region where Terraform actions will be implemented>
export TF\_VAR\_ssh\_private\_key\_bastion=$(cat <bastion node private ssh key>)
export TF\_VAR\_ssh\_private\_key\_non\_bastion=$(cat <non-bastion node private ssh key>)
export TF\_VAR\_public\_ip\_bastion="<bastion node public ip address>"
</pre>
- for deploying the project, run the following commands:
<pre>
source <path to your environment variables file> # save your environment variables to the environment in your CLI instance:
terraform init # initialize Terraform in the same directory as vars.tf
terraform plan # show the deployment plan before applying
terraform apply # apply the deployment plan, enter 'yes' when prompted
</pre>
- access your nodes once they have been attached. Verify the attachment on the nodes:
<pre>
sudo iscsiadm -m node # list the ISCSI nodes
</pre>