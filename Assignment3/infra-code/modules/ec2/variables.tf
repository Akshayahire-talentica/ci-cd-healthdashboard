variable "project_name" { type = string }
variable "subnet_id" { type = string }
variable "vpc_security_group_ids" { type = list(string) }
variable "instance_type" { 
    type = string
    default = "t3.micro"
  }
variable "key_name" { 
    type = string
    default = "" 
 }
variable "ami_id" { 
     type = string
     default = "" 
     }
variable "tags" { 
    type = map(string)
    default = {} 
 }
