variable "ecs_cluster_name" {
  description = "ECS cluster Name"
}

variable "db_host" {
  description = "RDS DB name"
}

variable "db_name" {
  description = "RDS DB name"
}

variable "db_user" {
  description = "RDS DB username"
}

variable "db_password" {
  description = "RDS DB password"
}

variable "wp_title" {
  description = "Wordpress title"
  default = "My Wordpress on ECS"
}

variable "wp_user" {
  description = "Wordpress username"
}

variable "wp_password" {
  description = "Wordpress password"
}

variable "wp_mail" {
  description = "Wordpress email"
  default = "kumar1010ashish@gmail.com"
}

variable "db_endpoint_arn" {
  
}

variable "vpc_id" {
  
}

variable "private_subnet" {
  
}

variable "public_subnet" {
  
}