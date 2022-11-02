variable "region" {
  default = "eu-west-2"
}

variable "public_subnet_cidrs" {
  type = list(string)
  default = [ "10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24" ]
}

variable "private_subnet_cidrs" {
  type = list(string)
  default = [ "10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24" ]
}

variable "availability_zones" {
  type = list(string)
  default = [ "eu-west-2a", "eu-west-2b", "eu-west-2c" ]
}

variable "listener_ports" {
  type    = map(number)
  default = {
    port_one = 443,
    port_two = 444
  }
}

variable "tg_ports" {
  type    = map(number)
  default = {
    port_one = 4443,
    port_two = 4444
  }
}

variable "ami_id" {
  type = string
  default = "some AMI ID"
}

variable "root_disk_size" {
  type = string
  default = "8"
}
