resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    "Name" = "Main VPC"
  }
}

resource "aws_subnet" "public_subnets" {
  count = length(var.public_subnet_cidrs)
  vpc_id = aws_vpc.main.id
  cidr_block = element(var.public_subnet_cidrs, count.index)
  availability_zone = element(var.availability_zones, count.index)

  tags = {
      Name = "Public Subnet ${count.index + 1}"
  }
}

resource "aws_subnet" "private_subnets" {
    count = length(var.private_subnet_cidrs)
    vpc_id = aws_vpc.main.id
    cidr_block = element(var.private_subnet_cidrs, count.index)
    availability_zone = element(var.availability_zones, count.index)

    tags = {
        Name = "Private Subnet ${count.index + 1}"
    }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "VPC IG"
  }
}

resource "aws_route_table" "second_rt" {
 vpc_id = aws_vpc.main.id
 
 route {
   cidr_block = "0.0.0.0/0"
   gateway_id = aws_internet_gateway.gw.id
 }
 
 tags = {
   Name = "Route Table for Internet access"
 }
}

resource "aws_route_table_association" "public_subnet_asso" {
 count = length(var.public_subnet_cidrs)
 subnet_id = element(aws_subnet.public_subnets[*].id, count.index)
 route_table_id = aws_route_table.second_rt.id
}

resource "aws_lb" "network_load_balancer" {
  name = "network-load-balancer"
  internal = false
  load_balancer_type = "network"
  ip_address_type = "ipv4"
  subnets = [for subnet in aws_subnet.public_subnets : subnet.id]
  # enable_cross_zone_load_balancing = true
}

resource "aws_lb_listener" "nlb_listener" {
  load_balancer_arn = aws_lb.network_load_balancer.arn
  for_each = var.listener_ports
  port = each.value
  protocol = "TCP"
  
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.target_group[each.key].arn
  }
}

resource "aws_lb_target_group" "target_group" {
  name = "nlb-target-group-${each.value}"
  for_each = var.tg_ports
  port = each.value
  protocol = "TCP"
  target_type = "instance"
  vpc_id = aws_vpc.main.id
}

resource "aws_instance" "ec2_instance" {
  count = length(var.availability_zones)
  instance_type = "t2.medium"
  # ami = var.ami_id
  ami = "ami-0c3fb0f6023840bc0"
  availability_zone = element(var.availability_zones, count.index)
  subnet_id = aws_subnet.private_subnets[count.index].id

  root_block_device {
    volume_size           = var.root_disk_size
    delete_on_termination = true
  }

  tags ={
    Name = "Linux_Instance-${count.index}"
  }
}

resource "aws_security_group" "ssh-security-group" {
  name        = "SSH Security Group"
  description = "Enable SSH access on Port 22"
  vpc_id      = aws_vpc.main.id
  ingress {
    description      = "SSH Access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["${var.ssh-location}"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  tags   = {
    Name = "SSH Security Group"
  }
}

resource "aws_key_pair" "key" {
  key_name   = "bastion_host_key"
  public_key = "${var.secret_0_public_key}"
}

resource "aws_instance" "bastion_host" {
  instance_type = "t2.2xlarge"
  ami = "AMI_ID"
  key_name = "SSH_KEY"
  availability_zone = var.availability_zone[0]
  subnet_id = aws_subnet.public_subnets[0].id
  associate_public_ip_address = true

  root_block_device {
    volume_size           = var.root_disk_size
    delete_on_termination = true
  }

  tags = {
    Name    = "Bastion host"
  }
}