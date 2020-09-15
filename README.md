# ms-aws-cicd-tf
Microservice baseline with infrastructure as code in aws using Terraform HCL. 

### Stack 
* Microservice in Spring Boot with Actuator. JIB plugin for building, image generation and image push
* CICD Pipeline: AWS CodeBuild, AWS CodePipeline and AWS ECR (as image repository).

### First Release
Scope: CodePipeline takes the source code from CodeCommit, and triggers the build using CodeBuild. CodeBuild logs in the ECR image registry and generates and pushes the image to AWS ECR. The instructions of codebuild are located in a buildspec.yml in ms repo.
This first release can be used as a kick start for using AWS resources and terraform HCL.
