//Plan Command (prod): terraform plan -var-file="production.tfvars" -out ./plan.out
//Apply Command (prod): terraform apply ./plan.out
//Destroy Command (prod): terraform destroy -var-file="production.tfvars"


provider "aws" {
    region = "us-east-1"
    alias = "main"

//  region  = "us-east-1"
//  profile = "092494271509_AWSAdministratorAccess"
//  alias   = "main"
}

// Dependencies: ECR Repo, Code Commit Repo

///////////////////

resource "aws_iam_role" "ms_codebuild_role" {
  name = var.codebuild_role

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF


  provider = aws.main
  tags = {

    Origin  = var.origin_tag
    Project = var.project_tag
  }

}


resource "aws_iam_role_policy" "ms_codebuild_policy" {
  name = var.codebuild_policy
  role = aws_iam_role.ms_codebuild_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
   {
      "Action": [
       "s3:PutObject",
       "s3:GetObject",
       "s3:GetObjectVersion",
       "s3:GetBucketVersioning"
      ],
      "Resource": [
        "${aws_s3_bucket.ms_pipeline_artifact_store.arn}",
        "${aws_s3_bucket.ms_pipeline_artifact_store.arn}/*"
      ],
      "Effect": "Allow"
    },
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
        "Effect": "Allow",
        "Action": [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetRepositoryPolicy",
            "ecr:DescribeRepositories",
            "ecr:ListImages",
            "ecr:DescribeImages",
            "ecr:BatchGetImage",
            "ecr:GetLifecyclePolicy",
            "ecr:GetLifecyclePolicyPreview",
            "ecr:ListTagsForResource",
            "ecr:DescribeImageScanFindings",
            "ecr:InitiateLayerUpload",
            "ecr:UploadLayerPart",
            "ecr:CompleteLayerUpload",
            "ecr:PutImage"
        ],
        "Resource": "*"
    }
  ]
}
EOF

  provider = aws.main


}






resource "aws_codebuild_project" "ms_build" {
  name         = var.codebuild_project_name
  service_role = aws_iam_role.ms_codebuild_role.arn
  artifacts {
    type = "CODEPIPELINE"
  }
  environment {
    compute_type = "BUILD_GENERAL1_SMALL"
    image        = "aws/codebuild/standard:3.0"
    type         = "LINUX_CONTAINER"
    // Ref: https://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref-available.html
  }
  source {
    type = "CODEPIPELINE"

  }


  provider = aws.main
  tags = {
    Origin  = var.origin_tag
    Project = var.project_tag
  }


}


resource "aws_iam_role" "ms_codepipeline_role" {
  name = var.codepipeline_role

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codepipeline.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

  provider = aws.main
  tags = {

    Origin  = var.origin_tag
    Project = var.project_tag
  }

}


resource "aws_iam_role_policy" "ms_codepipeline_policy" {
  name = "codepipeline_policy"
  role = aws_iam_role.ms_codepipeline_role.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect":"Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:GetBucketVersioning",
        "s3:PutObject"
      ],
      "Resource": [
        "${aws_s3_bucket.ms_pipeline_artifact_store.arn}",
        "${aws_s3_bucket.ms_pipeline_artifact_store.arn}/*"
      ]
    },
{
      "Action": [
        "codecommit:CancelUploadArchive",
        "codecommit:GetBranch",
        "codecommit:GetCommit",
        "codecommit:GetUploadArchiveStatus",
        "codecommit:UploadArchive"
      ],
      "Resource": "*",
      "Effect": "Allow"
    },


    {
      "Effect": "Allow",
      "Action": [
        "codebuild:BatchGetBuilds",
        "codebuild:StartBuild"
      ],
      "Resource": "*"
    }
  ]
}
EOF

  provider = aws.main


}




resource "aws_s3_bucket" "ms_pipeline_artifact_store" {
  bucket = var.codepipeline_artifact_store
  acl    = "private"


  provider = aws.main
  tags = {

    Origin  = var.origin_tag
    Project = var.project_tag
  }

}


resource "aws_codepipeline" "ms_pipeline" {

  name     = var.codepipeline_name
  role_arn = aws_iam_role.ms_codepipeline_role.arn

  artifact_store {
    location = aws_s3_bucket.ms_pipeline_artifact_store.bucket
    type     = "S3"
  }



  stage {
    name = "Source"

    action {
      category         = "Source"
      name             = "Source"
      owner            = "AWS"
      provider         = "CodeCommit"
      version          = "1"
      output_artifacts = ["source_output"]

      configuration = {
        RepositoryName = var.codepipeline_source_repo
        BranchName     = "master"
      }


    }
  } // https://docs.aws.amazon.com/codepipeline/latest/userguide/action-reference-CodeCommit.html


  stage {
    name = "Build"

    action {
      name             = "Build"
      category         = "Build"
      owner            = "AWS"
      provider         = "CodeBuild"
      input_artifacts  = ["source_output"]
      output_artifacts = ["build_output"]
      version          = "1"

      configuration = {
        ProjectName = var.codebuild_project_name
      }
    }
  }



  provider = aws.main
  tags = {

    Origin  = var.origin_tag
    Project = var.project_tag
  }

}




