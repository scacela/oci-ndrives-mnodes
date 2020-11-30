variable "ad" {default = "VXpT:US-ASHBURN-AD-1"}
variable "storage_server_name_regex_to_match" {default = "storage-server-*"}
variable "bv_storage_gb" {default = 51}
variable "vpus_per_gb" {default = 10} # 0: lower cost, 10: balanced, 20: higher performance
variable "bv_device_paths_to_add" {
    type = list(string)
    default = ["/dev/oracleoci/oraclevdg",
    "/dev/oracleoci/oraclevdh",
    "/dev/oracleoci/oraclevdi",
    "/dev/oracleoci/oraclevdj"]
}
variable "ssh_private_key_bastion" {}
variable "public_ip_bastion" {}
variable "user_bastion" {}
variable "compartment_ocid" {}
