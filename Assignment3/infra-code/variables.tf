variable "project_name" { type = string }
variable "region" { 
  type = string
 default = "ap-south-1" 
 }
variable "vpc_cidr" { 
  type = string
 default = "10.10.0.0/16"
  }
variable "public_subnet_cidr" { 
  type = string
 default = "10.10.1.0/24"
  }
variable "az" { 
  type = string
 default = "ap-south-1a"
  }
variable "instance_type" { 
  type = string
 default = "t3.micro"
  }
variable "key_name" { 
  type = string
 default = "" 
 }
variable "allow_ssh" { 
  type = bool
 default = false
  }
variable "ssh_cidr" { 
  type = string
 default = "0.0.0.0/0"
 }
variable "ami_id" { 
  type = string
 default = ""
  }
variable "default_tags" {
  type    = map(string)
  default = { Environment = "dev" }
}
variable "app_ports" {
  type = list(number)
  default = [ 0 ]
}