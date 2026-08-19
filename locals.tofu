##################################################################################
# LOCALS
##################################################################################

locals {

  student_name = "student${var.student_no}"

  region = var.region

  vpc_cidr = "10.255.0.0/16"

  availability_zone = "${local.region}a"

  managed_by = "OpenTofu"

  extra_cidrs_list = var.extra_cidrs != null ? split(",", var.extra_cidrs) : []

  local_cidr = var.in_github_action ? [] : ["${data.http.myip.response_body}/32"]

  final_cidrs_set = toset(concat(local.local_cidr, local.extra_cidrs_list))

  # number_of_subnets = 2

  instance_type = "m5.2xlarge"

  course_name = "f5xc-admin-smsv2"

  templatefile = "templates/cloud-config.tmpl"

  template_var = { token = volterra_token.token.id }

  common_tags = {
    Class      = "F5XC-Admin-smsv2"
    Class_Date = formatdate("YYYY-MM-DD", timestamp())
    Managed_By = "${local.managed_by}"
    Student    = "${local.student_name}"
  }

  vpc_tags = {
    Name = "${local.course_name}-${local.student_name}-vpc"
  }

  igw_tags = {
    Name = "${local.course_name}-${local.student_name}-igw"
  }

  igw_rt_tags = {
    Name = "${local.course_name}-${local.student_name}-igw-rt"
  }

  sg_slo_tags = {
    Name = "${local.course_name}-${local.student_name}-slo-sg"
  }

  sg_sli_tags = {
    Name = "${local.course_name}-${local.student_name}-sli-sg"
  }

  slo_ingress_rules_data = {
    for i, v in [
      ["icmp", -1, -1],
      ["tcp", 22, 22],
      ["tcp", 65500, 65500]
    ] : i => v
  }

  slo_ip_address_map = {
    for i, v in tolist(local.final_cidrs_set) : i => v
  }

  slo_ingress_security_group_rules = merge([
    for rule_key, rule_value in local.slo_ingress_rules_data : {
      for address_key, address_value in local.slo_ip_address_map :
      "rule_${rule_key}-addr_${address_key}" => {
        ip_protocol = rule_value[0]
        from_port   = rule_value[1]
        to_port     = rule_value[2]
        cidr_ipv4   = address_value
      }
    }
  ]...)

  subnets_info = [
    {
      name       = "public-slo"
      cidr_block = cidrsubnet(local.vpc_cidr, 8, 1)
      public_ip  = true
    },
    {
      name       = "private-sli"
      cidr_block = cidrsubnet(local.vpc_cidr, 8, 128)
      public_ip  = false
    }
  ]

  subnets = {
    for i, s in local.subnets_info :
    i => {
      subnet_name = s.name
      cidr_block  = "${s.cidr_block}"
      tags = {
        Name = "${local.course_name}-${local.student_name}-${local.availability_zone}-${s.name}"
      }
    }
  }

  enis = {
    for i, s in local.subnets_info :
    "eni${i}" => {
      subnet_key  = i # reference the subnet index
      private_ip  = "${s.cidr_block}"
      description = "${s.name} ENI (subnet ${i})"
    }
  }

  route_tables = {
    for i, s in local.subnets_info :
    i => {
      name = "${s.name}-rt"
      routes = s.public_ip ? {
        igw = {
          destination_cidr_block = "0.0.0.0/0"
          gateway_id             = aws_internet_gateway.this.id
        }
      } : {}
      tags = {
        Name = "${local.course_name}-${local.student_name}-${s.name}-rt"
      }
    }
  }

  flattened_routes = merge([
    for rt_key, rt in local.route_tables : {
      for r_key, r in rt.routes :
      "${rt_key}-${r_key}" => {
        route_table_id         = aws_route_table.this[rt_key].id
        destination_cidr_block = r.destination_cidr_block
        gateway_id             = r.gateway_id # may be null
      }
    }
  ]...)

}
