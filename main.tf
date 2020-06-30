provider "aws" {
  version = "2.33.0"
  region = var.aws_region
}

resource "aws_iam_role_policy" "example" {
  name = "example"
  role = "${aws_iam_role.example.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "dynamodb:*"
      ],
      "Effect": "Allow",
      "Resource": [
        "${aws_dynamodb_table.example.arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_appsync_graphql_api" "example" {
  authentication_type = "API_KEY"
  name                = "tf_appsync_example"
}

resource "aws_appsync_datasource" "example" {
  api_id           = "${aws_appsync_graphql_api.example.id}"
  name             = "tf_appsync_example"
  service_role_arn = "${aws_iam_role.example.arn}"
  type             = "AMAZON_DYNAMODB"
  dynamodb_config {
    table_name = "Flight-qebluapgb5hufleyrbja5rrvja-dev"
  }
}