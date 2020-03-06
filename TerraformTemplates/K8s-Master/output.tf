output "ec2instance" {
  value = aws_instance.project-k8s.public_ip
}