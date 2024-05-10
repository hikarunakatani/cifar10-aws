# Bucket to save CIFAR-10 dataset
resource "aws_s3_bucket" "dataset" {
  bucket = "${var.project_name}-bucket"
  force_destroy = true
}

resource "aws_s3_object" "example" {
  key        = "training_data"
  bucket     = aws_s3_bucket.dataset.id
  source     = "cifar10.zip"
}

data "aws_iam_policy_document" "bucket_policy" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "${aws_s3_bucket.dataset.arn}/*"
    ]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.ecs_task_exec.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.dataset.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

resource "aws_s3_bucket_public_access_block" "main" {
  bucket                  = aws_s3_bucket.dataset.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}