//Plan Command (prod): terraform plan -var-file="production.tfvars" -out ./plan.out
//Apply Command (prod): terraform apply ./plan.out
//Destroy Command (prod): terraform destroy -var-file="production.tfvars"

provider "aws" {
  region = "us-east-1"
  alias = "main"

  //region  = "us-east-1"
  //profile = "092494271509_AWSAdministratorAccess"
  //alias   = "main"
  //max_retries = 1
}


resource "aws_codecommit_repository" "ms_repo" {

  repository_name = var.ms_name
  description     = var.ms_description

  provider = aws.main
  tags = {

    Origin  = var.origin_tag
    Project = var.project_tag
  }

}



resource "aws_ecr_repository" "ms_image_repo" {
  name = var.image_repo

  provider = aws.main
  tags = {

    Origin  = var.origin_tag
    Project = var.project_tag
  }

}



output "ms_image_repo_uri" {
  value = aws_ecr_repository.ms_image_repo.repository_url
}

