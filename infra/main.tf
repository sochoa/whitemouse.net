provider "aws" {
  region     = "us-west-2"
}

data "aws_vpc" "default" {
  default = true
}

data "aws_acm_certificate" "blog" {
  domain      = "blog.whitemouse.net"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
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

resource "aws_instance" "blog" {
  ami = "ami-01ed306a12b7d1c96"
  instance_type = "t2.micro"
  key_name = "bitcycle-001"
  security_groups = ["allow_all"]
}

resource "aws_elb" "blog" {
  name               = "blog-elb"
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]

  listener {
    instance_port     = 8080
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port      = 8080
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "${data.aws_acm_certificate.blog.arn}"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:8080/"
    interval            = 30
  }

  instances                   = ["${aws_instance.blog.id}"]
  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

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
