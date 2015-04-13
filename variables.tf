variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "key_name" {
  description = "Name of the SSH keypair to use in AWS."
	default = "elastic"
}

variable "key_path" {
  description = "Path to the private portion of the SSH key specified."
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default = "ap-southeast-2"
}

variable "aws_security_group" {
  description = "Name of security group to use in AWS."
	default = "elasticsearch"
}

variable "aws_instance_type" {
  description = "EC2 instance type."
	default = "t2.medium"
}

# if you have multiple clusters sharing the same es_environment..?
variable "es_cluster" {
	description = "Elastic cluster name"
	default = "elasticsearch"
}

variable "es_environment" {
	description = "Elastic environment tag for auto discovery"
	default = "elasticsearch"
}

variable "es_num_nodes" {
	description = "Elastic nodes"
	default = "2"
}

# Ubuntu Precise 14.04 LTS (x64) built by packer
# See https://github.com/nadnerb/packer-elastic-search
variable "aws_amis" {
  default = {
		ap-southeast-2 = "ami-e95123d3"
  }
}

variable "aws_vpcs" {
	default = {
		ap-southeast-2 = "vpc-f753bd92"
	}
}

variable "aws_subnet-a-cidr" {
	default = {
		ap-southeast-2 = "172.16.55.0/25"
	}
}

variable "aws_subnet-b-cidr" {
	default = {
		ap-southeast-2 = "172.16.55.155/25"
	}
}
