#it is not possible to use _ in the names we need to replace it with -
locals {
  project_name_no_underscore = replace(var.project_name,"_","-")
}
resource "aws_networkfirewall_rule_group" "allowed_domain" {
  capacity = 100
  name     = "${local.project_name_no_underscore}-domains-allowed"
  type     = "STATEFUL"
  rule_group {
    rules_source {
      rules_source_list {
        generated_rules_type = "ALLOWLIST"
        target_types         = ["HTTP_HOST","TLS_SNI"]
        targets              = [".amazonaws.com", "gazzetta.it"]
      }
    }
  }

}

resource "aws_networkfirewall_rule_group" "forward" {
  capacity = 100
  name     = "${local.project_name_no_underscore}-forward-to-stateful"
  type     = "STATELESS"
  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {
        stateless_rule {
          priority = 5
          rule_definition {
            actions = ["aws:forward_to_sfe"]
            match_attributes {
              source_port {
                from_port = 0
                to_port   = 65535
              }
              source {
                address_definition = "0.0.0.0/0"
              }
              destination_port {
                from_port = 0
                to_port   = 65535
              }
              destination {
                address_definition = "0.0.0.0/0"
              }
              protocols = [6] # 6 is the TCP protocol number for IANA https://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml
            }
          }
        }
      }
    }
  }
}
resource "aws_networkfirewall_firewall_policy" "example" {
  name = local.project_name_no_underscore
  firewall_policy {
    stateless_default_actions = ["aws:forward_to_sfe"]
    stateless_fragment_default_actions = ["aws:forward_to_sfe"]
    stateless_rule_group_reference {
      priority     = 20
      resource_arn = aws_networkfirewall_rule_group.forward.arn
    }
    stateful_rule_group_reference {
      resource_arn = aws_networkfirewall_rule_group.allowed_domain.arn
    }
  }
}
resource "aws_networkfirewall_firewall" "example" {
  firewall_policy_arn = aws_networkfirewall_firewall_policy.example.arn
  name                = local.project_name_no_underscore
  vpc_id              = aws_vpc.main.id
  subnet_mapping {
    subnet_id          = module.public_no_restriction.subnet_id
  }
}


############### internet gateway routing


resource "aws_route_table" "gateway" {
  vpc_id = aws_vpc.main.id
  tags = {
      Name = "${var.project_name} Route for internet Gateway"
  }
  route {
    cidr_block           = var.cidr_pub_nat_gw
    vpc_endpoint_id =  (aws_networkfirewall_firewall.example.firewall_status[0].sync_states[*].attachment[0].endpoint_id)[0]
  }
}
resource "aws_route_table_association" "gateway" {
  gateway_id     = aws_internet_gateway.gw.id
  route_table_id = aws_route_table.gateway.id
}
