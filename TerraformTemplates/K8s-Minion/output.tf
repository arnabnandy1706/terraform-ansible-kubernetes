output "ec2instance" {
  value = "IP:[${element(aws_instance.project-k8s.*.private_ip, 0)},${element(aws_instance.project-k8s.*.private_ip, 1)}]"
}