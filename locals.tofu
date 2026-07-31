##################################################################################
# LOCALS
##################################################################################

locals {

  student_name = "student${var.student_no}"

  region = "us-east-1"

  availability_zone = "${local.region}a"

  managed-by = "OpenTofu"

  extra_cidrs_list = var.extra_cidrs != null ? split(",", var.extra_cidrs) : []

  instance_type = "m5.2xlarge"

  common_tags = {
    Class      = "F5XC-Admin-smsv2"
    Class_Date = formatdate("YYYY-MM-DD", timestamp())
    Managed-By = "${local.managed-by}"
    Student    = "${local.student_name}"
  }

  igw_rt_tags = {
    Name = "class-smsv2-${local.student_name}-igw-rt"
  }

  smsv2_slo_sub_tags = {
    Name = "class-smsv2-${local.student_name}-${local.availability_zone}-slo"
  }

  sg_tags = {
    Name = "class-smsv2-${local.student_name}-sg"
  }

}
