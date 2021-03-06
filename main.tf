provider "aws" {
  version = "2.33.0"
  region  = var.aws_region
}

resource "aws_iam_role" "example" {
  name = "example"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "appsync.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
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
        "${var.db_table_arn}"
      ]
    }
  ]
}
EOF
}

resource "aws_appsync_graphql_api" "example" {
  authentication_type = "API_KEY"
  name                = "tf_appsync_example"
  schema              = <<EOF
type Flight {
    id: ID!
    departureDate: String!
    departureAirportCode: String!
    departureAirportName: String!
    departureCity: String!
    departureLocale: String!
    arrivalDate: String!
    arrivalAirportCode: String!
    arrivalAirportName: String!
    arrivalCity: String!
    arrivalLocale: String!
    ticketPrice: Int!
    ticketCurrency: String!
    flightNumber: Int!
    seatAllocation: Int
    seatCapacity: Int!
}

type Flights {
    items: [Flight]
}

type Query {
    getFlight(id: ID!): Flight
    allFlights : Flights
}

schema {
    query: Query
}
EOF
}

resource "aws_appsync_resolver" "allFlights" {
  api_id      = "${aws_appsync_graphql_api.example.id}"
  field       = "allFlights"
  type        = "Query"
  data_source = "${aws_appsync_datasource.example.name}"

  request_template = <<EOF
  {
    "version": "2017-02-28",
    "operation": "Scan",
  }
  EOF

  response_template = <<EOF
    $util.toJson($ctx.result)
  EOF
}

resource "aws_appsync_resolver" "getFlight" {
  api_id      = "${aws_appsync_graphql_api.example.id}"
  field       = "getFlight"
  type        = "Query"
  data_source = "${aws_appsync_datasource.example.name}"

  request_template = <<EOF
  {
    "version": "2017-02-28",
    "operation": "GetItem",
    "key" : {
        "id" : $util.dynamodb.toDynamoDBJson($ctx.args.id)
    }
  }
  EOF

  response_template = <<EOF
    $util.toJson($ctx.result)
  EOF
}

resource "aws_appsync_datasource" "example" {
  api_id           = "${aws_appsync_graphql_api.example.id}"
  name             = "tf_appsync_example"
  service_role_arn = "${aws_iam_role.example.arn}"
  type             = "AMAZON_DYNAMODB"
  dynamodb_config {
    table_name = var.db_table_name
  }
}