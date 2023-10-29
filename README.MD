# About
Github Actions workflows for continuous integration and deployment (CI/CD) of a simple REST application on Kubernetes (EKS).

# Contents
- Terraform to deploy a small Kubernetes (EKS) cluster on AWS;
- REST application (nodejs);
- GitHub Actions workflows for CI/CD;
- Helm chart to deploy the REST application;

# Flow
After creating a new Pull Request, the github CI workflow is going to build the sourcecode and the docker image, then run the unit tests; if everything is ok it is going to push the docker image to AWS ECR;

Using the github CD workflow, it is possible to start the docker image deployment on kubernetes through the github UI. After that, the REST application should be running on kubernetes now.