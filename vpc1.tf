provider "aws" {
  region  = "ap-south-1"
}
resource "aws_vpc" "myvpc" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "myvpc1"
  }
}
resource "aws_subnet" "public" {
  vpc_id     = "${aws_vpc.myvpc.id}"
  cidr_block = "192.168.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet1"
  }
}
resource "aws_subnet" "private" {
  vpc_id     = "${aws_vpc.myvpc.id}"
  cidr_block = "192.168.1.0/24"

  tags = {
    Name = "subnet2"
  }
}
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.myvpc.id}"

  tags = {
    Name = "mygw1"
  }
}
resource "aws_route_table" "r" {
  vpc_id = "${aws_vpc.myvpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"

  }

  tags = {
    Name = "route1"
  }
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.r.id
}
resource "aws_security_group" "sg1" {
  name        = "securitygr1"
  description = "Allow ssh_http_icmp"
  vpc_id      = "${aws_vpc.myvpc.id}"

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "ICMP"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wordpresssg1"
  }
}
resource "aws_security_group" "sg2" {
  name        = "securitygr2"
  description = "Allow wordpresss1 only"
  vpc_id      = "${aws_vpc.myvpc.id}"

  ingress {
    description = "MYSQL"
    security_groups = ["${aws_security_group.sg1.id}"]
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "mysqlsg"
  }
}
resource "aws_security_group" "sg3" {
  name        = "securitygr3"
  description = "Allow _ssh"
  vpc_id      = "${aws_vpc.myvpc.id}"

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastionhostSGwp"
  }
}
resource "aws_security_group" "sg4" {
  name        = "securitygr4"
  description = "Allow _sg3"
  vpc_id      = "${aws_vpc.myvpc.id}"

  ingress {
    description = "ssh"
    security_groups = ["${aws_security_group.sg3.id}"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastionMYSQL"
  }
}
resource "aws_instance" "web" {
  ami = "ami-7e257211"
  instance_type = "t2.micro"
  key_name = "onkar12"
  vpc_security_group_ids = [ "${aws_security_group.sg1.id}" ]
  subnet_id = aws_subnet.public.id  
tags ={
    Name = "wordpress"
  }
  
}
resource "aws_instance" "web2" {
  ami = "ami-08706cb5f68222d09"
  instance_type = "t2.micro"
  key_name = "onkar12"
  vpc_security_group_ids = [ "${aws_security_group.sg2.id}" ]
  subnet_id = aws_subnet.private.id  
tags ={
    Name = "mysql"
  }
  
}
resource "aws_instance" "web3" {
  ami = "ami-08706cb5f68222d09"
  instance_type = "t2.micro"
  key_name = "onkar12"
  vpc_security_group_ids = [ "${aws_security_group.sg3.id}" ]
  subnet_id = aws_subnet.public.id  
tags ={
    Name = "bastionHOST"
  }
  
}

resource "aws_eip" "bar" {
  vpc = true

  depends_on                = ["aws_internet_gateway.gw"]
  instance  = "${aws_instance.web2.id}"
}
resource "aws_nat_gateway" "ngw" {
  allocation_id = "${aws_eip.bar.id}"
  subnet_id     = "${aws_subnet.public.id}"
  depends_on = ["aws_internet_gateway.gw"]

  tags = {
    Name = "natgw"
  }
}
resource "aws_route_table" "r1" {
  vpc_id = "${aws_vpc.myvpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.ngw.id}"

  }

tags = {
    Name = "route2"
  }
}
resource "aws_route_table_association" "ab" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.r1.id
}
















