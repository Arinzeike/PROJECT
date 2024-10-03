
# Variable for VPC ID
variable "vpc_id" {
  description = "vpc-00d60be840aaa91bc"
  type        = string
}

# Variable for AMI ID
variable "ami_id" {
  description = "ami-0866a3c8686eaeeba"
  type        = string
}

# Variable for the key pair name
variable "key_name" {
  description = "group11main1"
  type        = string
}

# Variable for the EC2 instance name
variable "instance_name" {
  description = "group"
  type        = string
  default     = "mr-peter"  
}
