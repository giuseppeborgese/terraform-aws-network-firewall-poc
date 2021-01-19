variable "project_name" {
  description = "prefix of most resources"
}

variable "vpc_cidr_block" {
  description = "the entire vpc cidr block"
}

variable "cidr_pub_no_restriction" {
  description = "public fw subnet cidr"
}
variable "cidr_pub_nat_gw" {
  description = "nat gw subnet cidr"
}

variable "cidr_private" {
  description = "private subnet cidr"
}
