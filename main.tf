##########################################
#  _____ ______  ______
# |  ___| ___\ \/ / ___|
# | |_  |___ \\  / |
# |  _|  ___) /  \ |___
# |_|   |____/_/\_\____|
#
##########################################

resource "volterra_securemesh_site_v2" "this" {
  name      = "${local.student_name}-smsv2"
  namespace = "system"
  labels = merge(
    local.common_tags,
    {
      "${local.student_name}-key" = "${local.student_name}-value"
    }
  )

  blocked_services {
    blocked_sevice {
      web_user_interface = true
      network_type       = "network_type"
    }
  }

  logs_streaming_disabled = true

  aws {
    not_managed {}
  }

  lifecycle {
    ignore_changes = [labels]
  }
}

resource "time_sleep" "wait" {
  create_duration  = "5s"
  destroy_duration = "5s"

  depends_on = [volterra_securemesh_site_v2.this]
}

resource "volterra_token" "token" {
  name      = "${local.student_name}-smsv2"
  namespace = "system"
  type      = 1
  site_name = "${local.student_name}-smsv2"

  depends_on = [volterra_securemesh_site_v2.this, time_sleep.wait]
}

# #########################################
#             _                      _
#  _ __   ___| |___      _____  _ __| | __
# | '_ \ / _ \ __\ \ /\ / / _ \| '__| |/ /
# | | | |  __/ |_ \ V  V / (_) | |  |   <
# |_| |_|\___|\__| \_/\_/ \___/|_|  |_|\_\
#
# #########################################

data "http" "myip" {
  url = "http://api.ipify.org"
}

resource "aws_vpc" "this" {
  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = true

  tags = merge(local.vpc_tags, local.common_tags)
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(local.igw_tags, local.common_tags)
}

resource "aws_subnet" "this" {
  for_each = local.subnets

  cidr_block                      = each.value.cidr_block
  vpc_id                          = aws_vpc.this.id
  map_public_ip_on_launch         = false
  availability_zone               = local.availability_zone
  assign_ipv6_address_on_creation = false

  tags = merge(each.value.tags, local.common_tags)
}

# ROUTING #
resource "aws_route_table" "this" {
  for_each = local.route_tables

  vpc_id = aws_vpc.this.id

  tags = merge(each.value.tags, local.common_tags)
}

resource "aws_route" "this" {
  for_each = local.flattened_routes

  route_table_id         = each.value.route_table_id
  destination_cidr_block = each.value.destination_cidr_block
  gateway_id             = each.value.gateway_id
}

resource "aws_route_table_association" "this" {
  for_each = local.subnets

  subnet_id      = aws_subnet.this[each.key].id
  route_table_id = aws_route_table.this[each.key].id
}

# # SECURITY GROUPS #
resource "aws_security_group" "slo" {
  name   = "${local.course_name}-${local.student_name}-slo-sg"
  vpc_id = aws_vpc.this.id

  tags = merge(local.sg_slo_tags, local.common_tags)
}

resource "aws_vpc_security_group_ingress_rule" "slo_ingress_rules" {
  for_each = local.slo_ingress_security_group_rules

  security_group_id = aws_security_group.slo.id
  ip_protocol       = each.value.ip_protocol
  from_port         = each.value.from_port
  to_port           = each.value.to_port
  cidr_ipv4         = each.value.cidr_ipv4
}

resource "aws_vpc_security_group_egress_rule" "slo_egress_rule_1" {
  security_group_id = aws_security_group.slo.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_security_group" "sli" {
  name   = "${local.course_name}-${local.student_name}-sli-sg"
  vpc_id = aws_vpc.this.id

  tags = merge(local.sg_sli_tags, local.common_tags)
}

resource "aws_vpc_security_group_ingress_rule" "sli_ingress_rule_1" {
  security_group_id = aws_security_group.sli.id
  ip_protocol       = "-1"
  cidr_ipv4         = local.subnets_info[1].cidr_block
}

resource "aws_vpc_security_group_egress_rule" "sli_egress_rule_1" {
  security_group_id = aws_security_group.sli.id
  ip_protocol       = "-1"
  cidr_ipv4         = local.subnets_info[1].cidr_block
}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.this.id
}

resource "aws_network_interface" "this" {
  for_each = local.enis

  subnet_id       = aws_subnet.this[each.value.subnet_key].id
  security_groups = each.value.subnet_key == 0 ? [aws_security_group.slo.id] : [aws_security_group.sli.id]
  description     = each.value.description

  tags = merge(local.common_tags, {
    Name = "${local.course_name}-${local.student_name}-${each.key}"
  })
}

resource "aws_eip" "this" {
  domain            = "vpc"
  network_interface = aws_network_interface.this["eni0"].id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.course_name}-${local.student_name}-eip"
    }
  )

  depends_on = [aws_instance.this]
}

# ##########################################
# #  _           _
# # (_)_ __  ___| |_ __ _ _ __   ___ ___
# # | | '_ \/ __| __/ _` | '_ \ / __/ _ \
# # | | | | \__ \ || (_| | | | | (_|  __/
# # |_|_| |_|___/\__\__,_|_| |_|\___\___|
# #
# ##########################################
#
# ##################################################################################
# # DATA
# ##################################################################################

data "aws_ssm_parameter" "ami" {
  name = "/aws/service/marketplace/prod-wrwzhcymymama/latest"
}

# ##################################################################################
# # RESOURCES
# ##################################################################################

resource "aws_key_pair" "this" {
  key_name   = var.key_name
  public_key = var.public_key

  tags = local.common_tags
}

# # # INSTANCES #
resource "aws_instance" "this" {
  ami           = nonsensitive(data.aws_ssm_parameter.ami.value)
  instance_type = local.instance_type
  key_name      = aws_key_pair.this.key_name
  user_data     = templatefile(local.templatefile, local.template_var)

  root_block_device {
    volume_size           = 80
    volume_type           = "gp2"
    delete_on_termination = true
  }

  primary_network_interface {
    network_interface_id = aws_network_interface.this["eni0"].id
  }

  tags = merge(
    local.common_tags,
    {
      Name             = "${local.course_name}-${local.student_name}-ec2",
      ves-io-site-name = volterra_securemesh_site_v2.this.name
    }
  )
}

resource "aws_network_interface_attachment" "secondary_attach" {
  instance_id          = aws_instance.this.id
  network_interface_id = aws_network_interface.this["eni1"].id
  device_index         = 1

}
