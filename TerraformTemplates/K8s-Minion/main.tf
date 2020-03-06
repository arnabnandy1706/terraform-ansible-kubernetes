provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_vpc" "project-k8s-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name ="K8s-Master-Server"
    Managed = "Kubernetes Cluster"
    Project = "K8s-Demo-ManagedCluster"
  }

}

resource "aws_subnet" "project-k8s-snet" {
  vpc_id     = "${aws_vpc.project-k8s-vpc.id}"
  cidr_block = "10.0.1.0/24"

  tags = {
    Name ="K8s-Master-Server"
    Managed = "Kubernetes Cluster"
    Project = "K8s-Demo-ManagedCluster"
  }

}

resource "aws_internet_gateway" "project-k8s-gw" {
  vpc_id = "${aws_vpc.project-k8s-vpc.id}"

  tags = {
    Name ="K8s-Master-Server"
    Managed = "Kubernetes Cluster"
    Project = "K8s-Demo-ManagedCluster"
  }

}

resource "aws_route" "project-k8s-rt" {
  route_table_id = "${aws_vpc.project-k8s-vpc.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.project-k8s-gw.id}"

  // tags = {
  //   Name ="K8s-Master-Server"
  //   Managed = "Kubernetes Cluster"
  //   Project = "K8s-Demo-ManagedCluster"
  // }

}

resource "aws_security_group" "project-k8s-sg" {
  name = "${lookup(var.awsprops, "secgroupname")}"
  description = "${lookup(var.awsprops, "secgroupname")}"
  vpc_id = "${aws_vpc.project-k8s-vpc.id}"

  // To Allow SSH Transport
  ingress {
    from_port = 0
    protocol = "tcp"
    to_port = 65000
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name ="K8s-Master-Server"
    Managed = "Kubernetes Cluster"
    Project = "K8s-Demo-ManagedCluster"
  }

}

// data "aws_subnet" "subnet_id" {
//   filter {
//     name = "tag:Project"
//     values = ["K8s-Demo-ManagedCluster"]
//   }
// }

// data "aws_security_group" "security_group_id" {
//   filter {
//     name = "tag:Project"
//     values = ["K8s-Demo-ManagedCluster"]
//   }
// }



resource "aws_instance" "project-k8s" {
  ami = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type = "${lookup(var.awsprops, "itype")}"
  // subnet_id = "${data.aws_subnet.subnet_id.id}"
  subnet_id = "${aws_subnet.project-k8s-snet.id}"
  associate_public_ip_address = "${lookup(var.awsprops, "publicip")}"
  key_name = "${var.key_name}"


  vpc_security_group_ids = [
    "${aws_security_group.project-k8s-sg.id}"
  ]

  root_block_device {
    delete_on_termination = true
    iops = 150
    volume_size = 50
    volume_type = "gp2"
  }
  tags = {
    Name ="K8s-Worker-Server"
    OS = "CentOS"
    Managed = "Kubernetes Cluster"
    Project = "K8s-Demo-ManagedCluster"
  }
  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "centos"
      private_key = "${file("${path.module}/keypad-02032020-us-east-1_New.pem")}"
      host = "${self.public_ip}"
    }
    inline = [
      "sudo yum -y install epel-release",
      "sudo yum -y install python-pip git ansible",
    ]
  }

  count = 2
  depends_on = [ aws_security_group.project-k8s-sg ]
}
