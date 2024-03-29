# Bucket to save CIFAR-10 dataset
resource "aws_s3_bucket" "main" {
  bucket = "${var.project_name}-bucket"
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
      "${aws_s3_bucket.main.arn}/*"
    ]
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.ecs_task_exec.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.main.id
  policy = data.aws_iam_policy_document.bucket_policy.json
}

