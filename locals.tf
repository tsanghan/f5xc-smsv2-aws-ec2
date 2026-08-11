##################################################################################
# LOCALS
##################################################################################

locals {

  student_name = "student${var.student_no}"

  region = var.region

  availability_zone = "${local.region}a"

  managed_by = "Terraform"

  extra_cidrs_list = var.extra_cidrs != null ? split(",", var.extra_cidrs) : []

  instance_type = "m5.2xlarge"

  course_name = "f5xc-admin-smsv2"

  templatefile = "template/cloud-config.tmpl"

  template_var = { token = volterra_token.class_smsv2_token.id }

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

  smsv2_slo_sub_tags = {
    Name = "${local.course_name}-${local.student_name}-${local.availability_zone}-slo"
  }

  sg_tags = {
    Name = "${local.course_name}-${local.student_name}-sg"
  }

  create_vpc_and_igw = local.region == "us-east-1"

  vpc_id = local.create_vpc_and_igw ? aws_vpc.class_smsv2[0].id : data.aws_vpc.selected[0].id
  igw_id = local.create_vpc_and_igw ? aws_internet_gateway.class_smsv2[0].id : data.aws_internet_gateway.selected[0].id

}
