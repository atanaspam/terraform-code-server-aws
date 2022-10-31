# terraform-code-server-aws

A Terraform module for deploying a standalone personal code-server instance on AWS with batteries incliuded.

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
