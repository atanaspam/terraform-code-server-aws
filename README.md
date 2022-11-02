# Code Server AWS Terraform Module

A Terraform module for deploying a standalone personal code-server instance on AWS with batteries incliuded.

## Features

* Dedicated code-server instance
* Authentication using Cognito and customizable username and password
* Image Builder factory to produce always up to date instance images
* Ability to attach persistent storage
* API allowing on-demand realtime instance scale up and down
* Ability to run server in private subnets for added ~~security~~ peace of mind

## Usage

### Basic

```hcl
module "code_server" {
source = "github.com/atanaspam/terraform-code-server-aws.git"

region           = "eu-central-1"
vpc_id           = data.aws_vpc.this.id
private_subnets  = data.aws_subnets.private.ids
public_subnets   = data.aws_subnets.public.ids
base_domain_name = "mydomain.net"
```

### Custom username and password

```hcl
module "code_server" {
source = "github.com/atanaspam/terraform-code-server-aws.git"

region               = "eu-central-1"
vpc_id               = data.aws_vpc.this.id
private_subnets      = data.aws_subnets.private.ids
public_subnets       = data.aws_subnets.public.ids
base_domain_name     = "mydomain.net"
code_server_username = "myCustomUsername"
code_server_password = "myPassword" # Don't hardcode me
```

## Manual scaling

It is possible to deploy the code-server instance in a scaled-down state. This means that all the supporting infra will be depoyed but the actual code server instace will not be started until explicitly requested. This is done to allow quick server spin-up while avoinding most (all?) of the fixed costs since (almost) all the other infra is charged on demand.

In order to scale your instace on demand, an API Gateway API has been created which takes HTTP POST requests that indicate the desired ASG replicas state for the code-server instace. The API endpoint requires the same username and password required to log in to the code-server instance, however authentication is performed via a different cognito endpoint. The controller URL is available as an output of the terraform module.

You can scale your instance using the examples below

Using curl and jq:
```bash
URL=$(terraform output -raw code_server_controller_endpoint)
AUTH_ENDPOINT=$(terraform output -raw code_server_controller_authentication_endpoint)
CS_USERNAME=$(terraform output -raw code_server_username)
CS_PASSWORD=$(terraform output -raw code_server_password)
COGNITO_CLIENT_ID=$(terraform output -raw cognito_client_id)
TOKEN=$(curl -X POST $AUTH_ENDPOINT \
--header 'X-Amz-Target: AWSCognitoIdentityProviderService.InitiateAuth' \
--header 'Content-Type: application/x-amz-json-1.1' \
--data-raw "$(cat <<EOF
{"AuthParameters" : {"USERNAME" : "$CS_USERNAME","PASSWORD" : "$CS_PASSWORD"},"AuthFlow" : "USER_PASSWORD_AUTH","ClientId" : "$COGNITO_CLIENT_ID"}
EOF
)" | jq -r '.AuthenticationResult.IdToken')

curl -X POST $URL --header "Authorization: $TOKEN" --data-raw '{"DesiredCapacity": 1}'
```

or using AWS CLI

```bash
URL=$(terraform output code_server_controller_endpoint)
USERNAME=$(terraform output code_server_username)
PASSWORD=$(terraform output code_server_password)
COGNITO_CLIENT_ID=$(terraform output cognito_client_id)

TOKEN=$(aws cognito-idp initiate-auth \
  --auth-flow USER_PASSWORD_AUTH \
  --auth-parameters \
  USERNAME=$USERNAME,PASSWORD=$PASSWORD \
  --client-id $COGNITO_CLIENT_ID \
  --qquery "AuthenticationResult.IdToken")

curl -X POST $URL --header "Authorization: $TOKEN" --data-raw '{"DesiredCapacity": 1}'
```

## Deploying to private or public subnets

It is possible to deploy the code-server instance in your private subnets. This allows you to run your instance in an isolated network without direct internet access. This is a very niche requirement and imposes some limitations on what your instance can do. If you dont know what is going on you should **not** use this.
If you choose to opt in for this setting, you also need to attach the appropriate VPC endpoints to your target VPC.

* SSM: The Image Builder and code-server instance use the SSM agent for access and provisioning
* SSM Messages: Same as above
* EC2 Messages: Standard EC2 communication inside a private subnet without a NAT gateway
* Image Builder: The Image Builder service spins up an instance in the private subnet in order to construct the base AMI
* S3: The Image Builder components are hosted in S3 and required for building the code-server image

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.14.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.1.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.14.0 |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.1.2 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_attach_persistent_storage"></a> [attach\_persistent\_storage](#input\_attach\_persistent\_storage) | When set to 'true' an EFS volume will be attached to the code-server where data can be persisted accros instance restarts. | `bool` | `false` | no |
| <a name="input_base_domain_name"></a> [base\_domain\_name](#input\_base\_domain\_name) | The domain to be used when genrerating a URL for the code-server instance. | `string` | n/a | yes |
| <a name="input_code_server_password"></a> [code\_server\_password](#input\_code\_server\_password) | The password to be used for logging in to the code-server instance. | `string` | `null` | no |
| <a name="input_code_server_username"></a> [code\_server\_username](#input\_code\_server\_username) | The username to be used for logging in to the code-server instance. | `string` | `"code-server"` | no |
| <a name="input_deploy_to_private_subnets"></a> [deploy\_to\_private\_subnets](#input\_deploy\_to\_private\_subnets) | If set to true all instances will be deployed in the private subnets. When set to true VPC endpoints are required and the 'private\_subnets' variable needs to be set. | `bool` | `false` | no |
| <a name="input_path_to_settings_json"></a> [path\_to\_settings\_json](#input\_path\_to\_settings\_json) | The path to a settings.json file to be used for vs code settings. | `string` | `null` | no |
| <a name="input_private_subnets"></a> [private\_subnets](#input\_private\_subnets) | A list of private subnets to be used by the code-server instance. | `list(string)` | `[]` | no |
| <a name="input_public_subnets"></a> [public\_subnets](#input\_public\_subnets) | A list of public subnets to be used by the code-server instance. | `list(string)` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | The AWS region to deploy the code-server instance to. | `string` | n/a | yes |
| <a name="input_start_code_server_on_deployment"></a> [start\_code\_server\_on\_deployment](#input\_start\_code\_server\_on\_deployment) | When set to 'true' the the instance will start automatically upon deployment. Otherwise a manual scale command is expected to start the server. | `bool` | `true` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The VPC ID where the code-server instance will be deployed. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_code_server_controller_authentication_endpoint"></a> [code\_server\_controller\_authentication\_endpoint](#output\_code\_server\_controller\_authentication\_endpoint) | The endpoint used to authenticate to the code server controller API. |
| <a name="output_code_server_controller_endpoint"></a> [code\_server\_controller\_endpoint](#output\_code\_server\_controller\_endpoint) | The endpoint which can be used to control wether the code-server instance should be running or not. |
| <a name="output_code_server_password"></a> [code\_server\_password](#output\_code\_server\_password) | The password for the code-server instance UI. |
| <a name="output_code_server_username"></a> [code\_server\_username](#output\_code\_server\_username) | The username for the code-server instance UI. |
| <a name="output_cognito_client_id"></a> [cognito\_client\_id](#output\_cognito\_client\_id) | The client id used to authenticate to the code server controller API. |
| <a name="output_instance_dns_record"></a> [instance\_dns\_record](#output\_instance\_dns\_record) | The DNS address for the code-server instance. |
<!-- END_TF_DOCS -->
