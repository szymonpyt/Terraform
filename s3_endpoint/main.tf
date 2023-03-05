resource "aws_vpc" "vpc" {
  cidr_block = "172.30.0.0/21"
  tags = {
    Name = "terra-vpc-szymon"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.public_cidr
  map_public_ip_on_launch = true
  tags = {
    Name = "terra-public-subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.vpc.id
  cidr_block = var.private_cidr
  tags = {
    Name = "terra-private-subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "gw-szymon"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    gateway_id = aws_internet_gateway.gw.id
    cidr_block = "0.0.0.0/0"
  }
  tags = {
    Name = "example"
  }
}

resource "aws_route_table_association" "pub" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id
  tags = {
   Name = "private_rt"
  }
}

resource "aws_route_table_association" "priv" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "first_key" {
  key_name   = "terra_public_key"
  public_key = tls_private_key.example.public_key_openssh
}

resource "aws_key_pair" "second_key" {
  key_name   = "terra_private_key"
  public_key = tls_private_key.example.public_key_openssh

  provisioner "local-exec" {
    command = "echo '${tls_private_key.example.private_key_pem}' > ./my_key.pem"
  }
}

resource "aws_security_group" "allow-ssh" {
  name   = "allow-ssh"
  vpc_id = aws_vpc.vpc.id
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_vpc_endpoint" "s3" {
 vpc_id       = aws_vpc.vpc.id
 service_name = "com.amazonaws.us-east-2.s3"
}

resource "aws_vpc_endpoint_route_table_association" "rta" {
  route_table_id  = aws_route_table.private_rt.id
  vpc_endpoint_id = aws_vpc_endpoint.s3.id 
}

resource "aws_iam_role" "ec2_s3_access_role" {
  name               = "ec2_access_s3"
  assume_role_policy = file("scripts/assume_role_policy.json")
}

resource "aws_iam_policy" "s3_policy" {
  name        = "s3_policy"
  description = "A policy to allow access to s3"
  policy      = file("scripts/policys3.json")
}

resource "aws_iam_policy_attachment" "ec2_to_s3" {
  name       = "ec2_to_s3"
  roles      = ["${aws_iam_role.ec2_s3_access_role.name}"]
  policy_arn = aws_iam_policy.s3_policy.arn
}

resource "aws_iam_instance_profile" "profile" {
  name = "profile"
  role = aws_iam_role.ec2_s3_access_role.name
}

resource "aws_instance" "instance1" {
  ami                    = lookup(var.ami, var.region)
  instance_type          = length(var.instance_type) == 0 ? "t2.micro" : var.instance_type[0]
  vpc_security_group_ids = [aws_security_group.allow-ssh.id]
  subnet_id              = aws_subnet.public_subnet.id
  key_name               = aws_key_pair.first_key.key_name
  user_data              = file("scripts/scr.sh")
  tags = {
    Name = "public-instance"
  }
}

resource "aws_instance" "instance2" {
  ami                    = lookup(var.ami, var.region)
  instance_type          = length(var.instance_type) == 0 ? "t2.micro" : var.instance_type[0]
  vpc_security_group_ids = [aws_security_group.allow-ssh.id]
  iam_instance_profile   = aws_iam_instance_profile.profile.name
  subnet_id              = aws_subnet.private_subnet.id
  key_name               = aws_key_pair.second_key.key_name
  tags = {
    Name = "private-instance"
  }
}
