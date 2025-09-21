variable "project_name" { type = string }
variable "vpc_id"       { type = string }
variable "app_ports"    { type = list(number) }
variable "allow_ssh"    { 
    type = bool 
    default = false 
    }
variable "ssh_cidr"     { 
    type = string
    default = "0.0.0.0/0"
  }
variable "tags"         { 
    type = map(string)
    default = {} 
    }
