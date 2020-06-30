provider "aws" {
  version = "2.33.0"
  region = var.aws_region
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
        "${var.db_table_name}"
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
        seatAllocation: Int # Disabling due to regression in amplify-cli 4.13.1: @deprecated(reason: "use seatCapacity instead. seatAllocation will be removed in the stable release.")
        seatCapacity: Int!
    }

    type ModelFlightConnection {
        items: [Flight]
    }

    type Query {
        listFlights() : ModelFlightConnection
    }

    schema {
        query: Query
        mutation: Mutation
    }
    EOF
    }
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