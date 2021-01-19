
# The VPC
resource "aws_vpc" "main" {
    cidr_block = var.vpc_cidr_block
    instance_tenancy = "default"
    enable_dns_hostnames = true
    enable_dns_support = true

    tags = {
      Name = var.project_name
    }

    lifecycle {
        prevent_destroy = false
    }
}

# Internet Gateway
resource "aws_internet_gateway" "gw" {
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "${var.project_name} IGW"
    }
    lifecycle {
        prevent_destroy = false
    }
}


##################### Routing Tables #########################
resource "aws_route_table" "public_no_restriction" {
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "${var.project_name} Public Routes No Restriction"
    }
    lifecycle {
        prevent_destroy = false
    }
}

resource "aws_route_table" "nat_gw_only" {
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "${var.project_name} Public Route for Nat GW with restriction"
    }
    lifecycle {
        prevent_destroy = false
    }
}

resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "${var.project_name} Private Route"
    }
    lifecycle {
        prevent_destroy = false
    }
}


################################# Subnets
#
data "aws_region" "current" {}


# Public
module "public_no_restriction" {
  source = "./subnet/"

  vpc_id = aws_vpc.main.id
  subnet_cidr_block = var.cidr_pub_no_restriction
  subnet_az = "${data.aws_region.current.name}a"
  subnet_name = "public no restriction"
  subnet_type = "Public no restriction"
  route_table_id = aws_route_table.public_no_restriction.id
}

module "nat_gw_only" {
  source = "./subnet/"

  vpc_id = aws_vpc.main.id
  subnet_cidr_block = var.cidr_pub_nat_gw
  subnet_az = "${data.aws_region.current.name}a"
  subnet_name = "Nat GW Public with restriction"
  subnet_type = "Public Restriction"
  route_table_id = aws_route_table.nat_gw_only.id
}

module "private" {
  source = "./subnet/"

  vpc_id = aws_vpc.main.id
  subnet_cidr_block = var.cidr_private
  subnet_az = "${data.aws_region.current.name}a"
  subnet_name = "private"
  subnet_type = "Private"
  route_table_id = aws_route_table.private.id
}

###### Nat GW and routes
resource "aws_nat_gateway" "gw" {
  allocation_id = aws_eip.gw.id
  subnet_id     = module.nat_gw_only.subnet_id

  tags = {
    Name = "NAT"
  }
}

resource "aws_eip" "gw" {
  vpc      = true
}
resource "aws_route" "internet_to_igw" {
  route_table_id = aws_route_table.public_no_restriction.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.gw.id
}

resource "aws_route" "internet_to_net_firewall" {
  route_table_id = aws_route_table.nat_gw_only.id
  destination_cidr_block = "0.0.0.0/0"
  vpc_endpoint_id =  (aws_networkfirewall_firewall.example.firewall_status[0].sync_states[*].attachment[0].endpoint_id)[0]
}

# Outgoing route for public Subnets
resource "aws_route" "private" {
  route_table_id = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.gw.id
}
