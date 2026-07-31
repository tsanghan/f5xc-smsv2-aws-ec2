# f5xc-smsv2-aws-ec2

1) Copy `.env.example` to `.env`
2) Copy `variables.tf.example` to `variables.tf`
3) Edit the `.env` file with proper values and vpd_id.
4) Generate a SSH key.
5) Edit the `variables.tf` file with your student number assigned to you and paste your public SSH key.
6) If you want to store TF state on S3, copy `backend.tf.example` to `backend.tf`. Edit `backend.tf` file with appropriate values.
7) Run `terraform init`
8) Run `terraform plan -out "tfplan"`
9) Run `terraform apply "tfplan"`
10) Watch and enjoy.
11) When you have enough enjoyment, run `terraform destroy -auto-approve`

This repo support both `terraform` and `tofu`.
If you need to switch from `terraform` to `tofu` or vice versa, you need to `clean` your project directory first with `just clean`.
Then you rerun `init`, `plan` and `apply` and finally, follow by `destroy`.