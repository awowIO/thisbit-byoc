variable "bucket_name" { type = string }

resource "aws_s3_bucket" "thisbit" {
  bucket = var.bucket_name
  lifecycle { prevent_destroy = true }
}

resource "aws_iam_user" "thisbit" {
  name = "thisbit-${var.bucket_name}"
}

resource "aws_iam_user_policy" "thisbit" {
  user = aws_iam_user.thisbit.name
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
      Resource = ["${aws_s3_bucket.thisbit.arn}/studio-media/*", "${aws_s3_bucket.thisbit.arn}/voice-reviews/*"]
    }]
  })
}

output "endpoint" { value = "https://s3.${aws_s3_bucket.thisbit.region}.amazonaws.com" }
output "bucket" { value = aws_s3_bucket.thisbit.bucket }
output "iam_user" { value = aws_iam_user.thisbit.name }
