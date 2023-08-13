README:

This is the folder structure
project/
├── main.tf
├── variables.tf
├── outputs.tf
├── lambdas/
│   ├── lambda1.py
│   └── lambda2.py
├── tfvars/
│   ├── dev.tfvars
│   └── prod.tfvars
└── README.md

This complete project sets up the infrastructure and lambdas as specified, including SSL authentication using ACM, IP restriction, and the necessary AWS resources. Remember to replace "x.x.x.x/32" and "y.y.y.y/32" with the actual IP addresses you want to allow access from in the files under /tfvars.


To apply the Terraform configuration using the appropriate variable file:

bash

terraform init
terraform apply -var-file=tfvars/dev.tfvars

or

bash

terraform init
terraform apply -var-file=tfvars/prod.tfvars