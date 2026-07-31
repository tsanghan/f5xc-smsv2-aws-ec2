##########################################
#  _____ ______  ______
# |  ___| ___\ \/ / ___|
# | |_  |___ \\  / |
# |  _|  ___) /  \ |___
# |_|   |____/_/\_\____|
#
##########################################

resource "volterra_securemesh_site_v2" "class_smsv2" {

  name      = "${local.student_name}-smsv2"
  namespace = "system"
  labels = merge(
    local.common_tags,
    {
      "${local.student_name}-key" = "${local.student_name}-value"
    }
  )


  // One of the arguments from this list "block_all_services blocked_services" must be set

  blocked_services {
    blocked_sevice {
      // One of the arguments from this list "dns ssh web_user_interface" can be set

      web_user_interface = true

      network_type = "network_type"
    }
  }

  // One of the arguments from this list "log_receiver log_receiver_with_net logs_streaming_disabled" must be set

  logs_streaming_disabled = true

  // One of the arguments from this list "aws azure baremetal equinix gcp kvm nutanix oci openshift_virtualization openstack rseries vmware" must be set

  aws {
    // "not_managed" must be set

    not_managed {}
  }

  // lifecycle is a Terraform meta-argument — it controls resource behavior through
  // settings such as ignore_changes, create_before_destroy, and prevent_destroy.
  lifecycle {
    ignore_changes = [
      labels
    ]
  }
}

resource "time_sleep" "wait" {
  create_duration  = "5s"
  destroy_duration = "5s"

  depends_on = [volterra_securemesh_site_v2.class_smsv2]
}

resource "volterra_token" "class_smsv2_token" {

  name      = "${local.student_name}-smsv2"
  namespace = "system"
  type      = 1
  site_name = "${local.student_name}-smsv2"

  depends_on = [volterra_securemesh_site_v2.class_smsv2, time_sleep.wait]

}

data "template_file" "cloud_init" {

  template = file("template/cloud-config.tmpl")
  vars = {
    token = volterra_token.class_smsv2_token.id
  }
}

data "http" "myip" {
  url = "http://api.ipify.org"
}

# #########################################
#             _                      _
#  _ __   ___| |___      _____  _ __| | __
# | '_ \ / _ \ __\ \ /\ / / _ \| '__| |/ /
# | | | |  __/ |_ \ V  V / (_) | |  |   <
# |_| |_|\___|\__| \_/\_/ \___/|_|  |_|\_\
#
# #########################################

data "aws_internet_gateway" "selected" {
  filter {
    name   = "attachment.vpc-id"
    values = [var.vpc_id]
  }
}

resource "aws_subnet" "class_smsv2" {
  cidr_block              = "10.255.${var.student_no}.0/24"
  vpc_id                  = var.vpc_id
  map_public_ip_on_launch = false
  availability_zone       = local.availability_zone

  tags = merge(local.smsv2_slo_sub_tags, local.common_tags)

}

# ROUTING #
resource "aws_route_table" "class_smsv2" {
  vpc_id = var.vpc_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.selected.id
  }

  tags = merge(local.igw_rt_tags, local.common_tags)

}

resource "aws_route_table_association" "class_smsv2" {
  subnet_id      = aws_subnet.class_smsv2.id
  route_table_id = aws_route_table.class_smsv2.id
}

# # SECURITY GROUPS #
resource "aws_security_group" "class_smsv2" {
  name   = "class_smsv2_${local.student_name}_sg"
  vpc_id = var.vpc_id

  tags = merge(local.sg_tags, local.common_tags)

}

resource "aws_vpc_security_group_ingress_rule" "class_smsv2_ingress_rule_1" {
  for_each = toset(
    concat(
      ["${data.http.myip.response_body}/32"],
      local.extra_cidrs_list
    )
  )

  security_group_id = aws_security_group.class_smsv2.id
  ip_protocol       = "icmp"
  from_port         = -1
  to_port           = -1
  cidr_ipv4         = each.key
}

resource "aws_vpc_security_group_ingress_rule" "class_smsv2_ingress_rule_2" {
  for_each = toset(
    concat(
      ["${data.http.myip.response_body}/32"],
      local.extra_cidrs_list
    )
  )

  security_group_id = aws_security_group.class_smsv2.id
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_ipv4         = each.key
}

resource "aws_vpc_security_group_ingress_rule" "class_smsv2_ingress_rule_3" {
  for_each = toset(
    concat(
      ["${data.http.myip.response_body}/32"],
      local.extra_cidrs_list
    )
  )

  security_group_id = aws_security_group.class_smsv2.id
  ip_protocol       = "tcp"
  from_port         = 65500
  to_port           = 65500
  cidr_ipv4         = each.key
}

resource "aws_vpc_security_group_egress_rule" "class_smsv2_egress_rule_1" {
  security_group_id = aws_security_group.class_smsv2.id
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_default_security_group" "default" {
  vpc_id = var.vpc_id
}

resource "aws_eip" "class_smsv2" {

  instance = aws_instance.class_smsv2.id
  domain   = "vpc"

  tags = merge(
    local.common_tags,
    {
      Name = "class_smsv2_${local.student_name}_eip"
    }
  )
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

resource "aws_key_pair" "class_smsv2" {
  key_name   = var.key_name
  public_key = var.public_key

  tags = local.common_tags
}

# # # INSTANCES #
resource "aws_instance" "class_smsv2" {

  ami                    = nonsensitive(data.aws_ssm_parameter.ami.value)
  instance_type          = local.instance_type
  subnet_id              = aws_subnet.class_smsv2.id
  vpc_security_group_ids = [aws_security_group.class_smsv2.id]
  key_name               = aws_key_pair.class_smsv2.key_name
  user_data              = data.template_file.cloud_init.rendered

  root_block_device {
    volume_size           = 80    # size in GB
    volume_type           = "gp2" # general‑purpose SSD; change to gp3, io1, etc. if desired
    delete_on_termination = true
  }

  tags = merge(
    local.common_tags,
    {
      Name             = "${local.student_name}-ec2",
      ves-io-site-name = volterra_securemesh_site_v2.class_smsv2.name
    }
  )
}
