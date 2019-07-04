output "blog_ec2_instance" {
  value = "ssh centos@${aws_instance.blog.public_dns}"
}
