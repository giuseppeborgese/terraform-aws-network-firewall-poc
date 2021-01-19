# terraform-aws-network-firewall-poc
A POC for the AWS Network Firewall Service, full VPC with a Single AZ

Full documentation and explanation soon on https://giuseppeborgese.medium.com/how-to-build-an-aws-network-firewall-environment-8a212cfb7ef3

![diagram](https://raw.githubusercontent.com/giuseppeborgese/terraform-aws-network-firewall-poc/master/diagram.png)

Youtube video with demo https://youtu.be/Xb-matrBNOs

```
module "network_firewall_pocv2" {
  source  = "giuseppeborgese/network-firewall-poc/aws"

  project_name = "terr_net_fw_test"
  vpc_cidr_block = "172.16.0.0/16"
  cidr_pub_no_restriction = "172.16.0.0/24"
  cidr_pub_nat_gw = "172.16.1.0/24"
  cidr_private = "172.16.2.0/24"
}
```
