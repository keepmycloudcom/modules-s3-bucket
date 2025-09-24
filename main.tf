### Variables
variable "name"   { type = string }
variable "tags"   { type = map(string) }
variable "bucket" { type = string }
variable "project_domain" { type = string }

### S3 Bucket
resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket

  tags = var.tags
}

# CORS 
resource "aws_s3_bucket_cors_configuration" "this" {
  bucket = aws_s3_bucket.bucket.bucket

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["https://${var.project_domain}"]
    max_age_seconds = 3000
  }
}

# Ensure no public access is possible
resource "aws_s3_bucket_public_access_block" "bucket" {
  bucket = aws_s3_bucket.bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

### IAM Policy: Read/write
resource "aws_iam_policy" "s3-rw" {
  name = "${var.name}-BucketRW-POLICY"
  path = "/"

  policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "s3:GetObject*",
            "s3:PutObject*",
            "s3:DeleteObject*",
            "s3:RestoreObject"
          ],
          "Resource": "${aws_s3_bucket.bucket.arn}/*"
        },
        {
          "Effect": "Allow",
          "Action": [
            "s3:ListBucket",
            "s3:GetBucketLocation"
          ],
          "Resource": "${aws_s3_bucket.bucket.arn}"
        }
      ]
    }
    EOF
}

### IAM Policy: Read-only
resource "aws_iam_policy" "s3-ro" {
  name = "${var.name}-BucketRO-POLICY"
  path = "/"

  policy = <<-EOF
    {
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Action": [
            "s3:GetObject*"
          ],
          "Resource": "${aws_s3_bucket.bucket.arn}/*"
        },
        {
          "Effect": "Allow",
          "Action": [
            "s3:ListBucket",
            "s3:GetBucketLocation"
          ],
          "Resource": "${aws_s3_bucket.bucket.arn}"
        }
      ]
    }
    EOF
}

### Outputs
output "bucket" {
  value = {
    id  = aws_s3_bucket.bucket.id
    arn = aws_s3_bucket.bucket.arn
  }
}

output "rw_policy_arn" { value = aws_iam_policy.s3-rw.arn }
output "ro_policy_arn" { value = aws_iam_policy.s3-ro.arn }

# vim:filetype=terraform ts=2 sw=2 et:
