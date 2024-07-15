#template for wp container
data "template_file" "wp-container" {
  template = "${file("${path.module}/wordpress.json")}"

  vars = {
    db_host     = var.db_host
    db_name     = var.db_name
    db_user     = var.db_user
    db_password = var.db_password
    wp_title    = var.wp_title
    wp_user     = var.wp_user
    wp_password = var.wp_password
    wp_mail     = var.wp_mail
  }
}
# ECS cluster
resource "aws_ecs_cluster" "wordpress_cluster" {
  name = "wordpress-cluster"
}

# S3 bucket for media storage
resource "aws_s3_bucket" "wordpress_media_bucket" {
  bucket = "wordpress-media-bucket-vow"
}

resource "aws_s3_bucket_ownership_controls" "wordpress_media_bucket_owner" {
  bucket = aws_s3_bucket.wordpress_media_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "example" {
  depends_on = [aws_s3_bucket_ownership_controls.wordpress_media_bucket_owner]

  bucket = aws_s3_bucket.wordpress_media_bucket.id
  acl    = "private"
}

# ECS task definition for WordPress
resource "aws_ecs_task_definition" "wordpress_task" {
  family                   = "wordpress"
  container_definitions   = data.template_file.wp-container.rendered
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_task_role.arn
}

resource "aws_ecs_service" "wp-ecs-svc" {
    name = "wp-ecs-svc"
    cluster = aws_ecs_cluster.wordpress_cluster.id
    task_definition = aws_ecs_task_definition.wordpress_task.arn
    enable_ecs_managed_tags = true
    desired_count = 1
    launch_type     =  "FARGATE"

    network_configuration {
      subnets =  ["${var.public_subnet}","${var.private_subnet}"]
      assign_public_ip = true
      security_groups = [aws_security_group.wordpress_sg.id]
    }
}

resource "aws_iam_role" "ecs_task_role" {
  name = "ecs-task-role"

  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "ecs_task_policy" {
  name        = "ecs-task-policy"
  description = "Policy for ECS tasks to access RDS and S3"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "rds-db:connect"
        ],
        "Resource": [
          "${var.db_endpoint_arn}"
        ]
      },
      {
        "Effect": "Allow",
        "Action": [
          "s3:GetObject",
          "s3:PutObject"
        ],
        "Resource": [
          aws_s3_bucket.wordpress_media_bucket.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = aws_iam_policy.ecs_task_policy.arn
}


resource "aws_iam_role_policy_attachment" "ecs_exec_policy_attachment" {
  role       = aws_iam_role.ecs_task_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonECS_FullAccess"
}


resource "aws_security_group" "wordpress_sg" {
  name = "wordpress-sg"
  vpc_id = var.vpc_id
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

    ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
