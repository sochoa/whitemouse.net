provider "aws" {
  region     = "us-west-2"
}

terraform {
  backend "s3" {
    # Replace this with your bucket name!
    bucket         = "blog.prod.tf.bitcycle"
    key            = "terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
  }
}

data "aws_vpc" "default" {
  default = true
}

data "aws_acm_certificate" "blog" {
  domain      = "blog.whitemouse.net"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}


resource "aws_security_group" "allow_all_ssh_from_anywhere" {
  name        = "allow_all_ssh_from_anywhere"
  description = "Allow all inbound SSH traffic"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_internal_alt_http" {
  name        = "allow_internal_alt_http"
  description = "Allow all inbound HTTP traffic"
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }
  ingress {
    from_port   = 8443
    to_port     = 8443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow_all_http" {
  name        = "allow_all_http"
  description = "Allow all inbound HTTP traffic"
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "blog" {
  ami = "ami-01ed306a12b7d1c96"
  instance_type = "t2.micro"
  key_name = "bitcycle-001"
  security_groups = ["allow_all_ssh_from_anywhere", "allow_internal_alt_http"]
}

resource "aws_elb" "blog" {
  name               = "blog-elb"
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]

  listener {
    instance_port      = 80
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "${data.aws_acm_certificate.blog.arn}"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 30
  }

  instances                   = ["${aws_instance.blog.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
  security_groups = ["${aws_security_group.allow_all_http.id}"]

  tags = {
    Name = "blog-elb"
  }
}

data "aws_route53_zone" "blog" {
  name = "whitemouse.net."
}

resource "aws_route53_record" "blog" {
  zone_id = "${data.aws_route53_zone.blog.zone_id}"
  name    = "blog.${data.aws_route53_zone.blog.name}"
  type    = "CNAME"
  ttl     = "5"
  set_identifier = "blog"
  records        = ["${aws_elb.blog.dns_name}"]
  weighted_routing_policy {
    weight = 10
  }
}
