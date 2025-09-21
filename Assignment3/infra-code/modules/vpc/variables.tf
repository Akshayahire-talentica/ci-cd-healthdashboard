variable "project_name" { type = string }
variable "cidr_block" { type = string }
variable "public_subnet_cidr" { type = string }
variable "az" { 
     type = string 
    }
variable "enable_dns_hostnames" { 
     type = bool
     default = true 
     }
variable "enable_dns_support"   { 
     type = bool
     default = true
    }
variable "tags" { 
    type = map(string)
    default = {}
  }
