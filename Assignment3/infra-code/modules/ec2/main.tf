data "aws_ami" "al2023" {
  count       = var.ami_id == "" ? 1 : 0
  most_recent = true
  owners      = ["137112412989"]

  filter { 
    name = "name" 
    values = ["al2023-ami-*-x86_64"]
     }
  filter { 
    name = "architecture" 
    values = ["x86_64"]
     }
  filter { 
    name = "virtualization-type" 
    values = ["hvm"] 
    }
}

locals { selected_ami = var.ami_id != "" ? var.ami_id : data.aws_ami.al2023[0].id }

resource "aws_instance" "this" {
  ami                         = local.selected_ami
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.vpc_security_group_ids
  associate_public_ip_address = true
  key_name                    = var.key_name != "" ? var.key_name : null

  user_data = file("${path.module}/user_data.sh")
  tags      = merge(var.tags, { Name = "${var.project_name}-ec2" })
}
