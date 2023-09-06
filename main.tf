data "aws_availability_zones" "zones" {
  state = "available"
}
resource "aws_vpc" "main_vpc" { #vpc creation
  cidr_block           = "172.16.0.0/16"
  enable_dns_hostnames = "true"
  instance_tenancy     = "default"
  enable_dns_support   = "true"

  tags = {
    Name = "${var.project}_${var.env}_vpc"

  }
}
resource "aws_subnet" "public_sub" {
  count                   = 3
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.main_vpc.cidr_block, 3, "${count.index}")
  availability_zone       = data.aws_availability_zones.zones.names["${count.index}"]
  map_public_ip_on_launch = "true"

  tags = {
    Name = "${var.project}_${var.env}_public_subnet${count.index + 1}"
  }
}
resource "aws_subnet" "private_sub" {
  count                   = 3
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.main_vpc.cidr_block, 3, "${count.index + 3}")
  availability_zone       = data.aws_availability_zones.zones.names["${count.index}"]
  map_public_ip_on_launch = "false"

  tags = {
    Name = "${var.project}_${var.env}_private_subnet${count.index + 4}"
  }
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.project}_${var.env}_igw"
  }
}
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id

  }
  tags = {
    Name = "${var.project}_${var.env}_public_rt"
  }
}
resource "aws_eip" "natgw-eip" {
  domain = "vpc"
  tags = {
    Name = "${var.project}_${var.env}_natgw-eip"
  }
}
resource "aws_nat_gateway" "nat_igw" {
  allocation_id = aws_eip.natgw-eip.id
  subnet_id     = aws_subnet.public_sub[1].id

  tags = {
    Name = "${var.project}_${var.env}_natgw"
  }

  depends_on = [aws_internet_gateway.igw, aws_eip.natgw-eip]
}
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_igw.id

  }
  tags = {
    Name = "${var.project}_${var.env}_private_rt"
  }
}
resource "aws_route_table_association" "public_rt_asso" {
  count          = 3
  subnet_id      = aws_subnet.public_sub["${count.index}"].id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "private_rt_asso" {
  count          = 3
  subnet_id      = aws_subnet.private_sub["${count.index}"].id
  route_table_id = aws_route_table.private_rt.id
}
resource "aws_security_group" "bastion_sg" {
  name        = "${var.project}_bastion_sg"
  description = "Allow ssh inbound traffic"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "allow ssh traffic"
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
    Name = "${var.project}_bastion_sg"
  }
}
resource "aws_security_group" "frontend_sg" {
  name        = "${var.project}_frontend_sg"
  description = "Allow 80 inbound traffic"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "allow web traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description     = "allow ssh traffic"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}_frontend_sg"
  }
}
resource "aws_security_group" "backend_sg" {
  name        = "${var.project}_backend_sg"
  description = "Allow 3306 inbound traffic"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "allow ssh traffic"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"

    security_groups = [aws_security_group.frontend_sg.id]
  }
  ingress {
    description     = "allow ssh traffic"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project}_backend_sg"
  }
}
resource "aws_key_pair" "sshkey" {
  key_name   = "${var.project}_mykey"
  public_key = file("mykey.pub")
  tags = {
    Name = "${var.project}_mykey"
  }
}
resource "aws_eip" "bastion_eip" {
  domain = "vpc"
  tags = {
    Name = "${var.project}_${var.env}_bastion_eip"
  }

}
resource "aws_eip" "frontend_eip" {
  domain = "vpc"
  tags = {
    Name = "${var.project}_${var.env}_frontend_eip"
  }

}
resource "aws_instance" "bastion" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = aws_key_pair.sshkey.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  subnet_id              = aws_subnet.public_sub[1].id
  user_data              = file("C:\\terrafrom-class9\\datascript.sh")
  lifecycle {
    create_before_destroy = true

  }
  depends_on = [aws_eip.bastion_eip]
  tags = {
    Name = "${var.project}_${var.env}_bastion_srv"
  }
}
resource "aws_instance" "frontend" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = aws_key_pair.sshkey.id
  vpc_security_group_ids = [aws_security_group.frontend_sg.id]
  subnet_id              = aws_subnet.public_sub[0].id
  user_data              = file("C:\\terrafrom-class9\\web_datascript.sh")
  lifecycle {
    create_before_destroy = true

  }
  depends_on = [aws_eip.frontend_eip]
  tags = {
    Name = "${var.project}_${var.env}_frontend_srv"

  }
}

resource "aws_eip_association" "eip_assoc_frontend" {
  instance_id   = aws_instance.frontend.id
  allocation_id = aws_eip.frontend_eip.id
}
resource "aws_eip_association" "eip_assoc_bastion" {
  instance_id   = aws_instance.bastion.id
  allocation_id = aws_eip.bastion_eip.id
}

resource "aws_instance" "backend" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = aws_key_pair.sshkey.id
  vpc_security_group_ids = [aws_security_group.backend_sg.id]
  subnet_id              = aws_subnet.private_sub[1].id
  lifecycle {
    create_before_destroy = true

  }
  tags = {
    Name = "${var.project}_${var.env}_backend_srv"
  }
}

resource "aws_route53_zone" "avincm_private_domain" {
  name = var.private_domain

  vpc {
    vpc_id = aws_vpc.main_vpc.id
  }

}
resource "aws_route53_record" "bastion_record" {
  zone_id = aws_route53_zone.avincm_private_domain.zone_id
  name    = "bastion.${var.private_domain}"
  type    = "A"
  ttl     = 5
  records = [aws_instance.bastion.private_ip]
}
resource "aws_route53_record" "frontend_record" {
  zone_id = aws_route53_zone.avincm_private_domain.zone_id
  name    = "frontend.${var.private_domain}"
  type    = "A"
  ttl     = 5
  records = [aws_instance.frontend.private_ip]
}
resource "aws_route53_record" "backend_record" {
  zone_id = aws_route53_zone.avincm_private_domain.zone_id
  name    = "backend.${var.private_domain}"
  type    = "A"
  ttl     = 5
  records = [aws_instance.backend.private_ip]
}
resource "aws_route53_record" "frontend_public_record" {
  zone_id = var.public_zone_id
  name    = "www.${var.public_domain}"
  type    = "A"
  ttl     = 5
  records = [aws_eip.frontend_eip.public_ip]
}
resource "aws_route53_record" "bastion_public_record" {
  zone_id = var.public_zone_id
  name    = "bastion.${var.public_domain}"
  type    = "A"
  ttl     = 5
  records = [aws_eip.bastion_eip.public_ip]
}