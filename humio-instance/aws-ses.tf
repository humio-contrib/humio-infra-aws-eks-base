resource "aws_iam_user" "smtp_user" {
  name = "${var.humio_instance}-alerts"

}

resource "aws_iam_access_key" "smtp_user" {
  user = aws_iam_user.smtp_user.name

}


data "aws_iam_policy_document" "ses_sender" {
  statement {
    actions   = ["ses:SendRawEmail"]
    resources = ["*"]
  }

}

resource "aws_iam_policy" "ses_sender" {
  name        = "${var.humio_instance}-ses"
  description = "Allows sending of e-mails via Simple Email Service"
  policy      = data.aws_iam_policy_document.ses_sender.json

}


resource "aws_iam_user_policy_attachment" "ses_sender" {
  user       = aws_iam_user.smtp_user.name
  policy_arn = aws_iam_policy.ses_sender.arn

}



resource "aws_ses_email_identity" "ses" {
  email = "${var.humio_instance}-alerts@${var.domain_name}"

}

resource "aws_ses_configuration_set" "humio" {
  name = "${var.humio_instance}-ses"

  delivery_options {
    tls_policy = "Require"
  }
  reputation_metrics_enabled = true

}

resource "aws_ses_event_destination" "cloudwatch" {
  name                   = var.humio_instance
  configuration_set_name = aws_ses_configuration_set.humio.name
  enabled                = true
  matching_types         = ["bounce", "send"]

  cloudwatch_destination {
    default_value  = "default"
    dimension_name = "dimension"
    value_source   = "emailHeader"
  }

}

