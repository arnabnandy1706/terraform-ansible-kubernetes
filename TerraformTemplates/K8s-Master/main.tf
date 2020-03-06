provider "aws" {
  region = "${var.aws_region}"
}

// resource "aws_vpc" "project-k8s-vpc" {
//   cidr_block = "10.0.0.0/16"
//   enable_dns_support = true
//   enable_dns_hostnames = true

//   tags = {
//     Name ="K8s-Master-Server"
//     Managed = "Kubernetes Cluster"
//     Project = "K8s-Demo-ManagedCluster"
//   }

// }

// resource "aws_subnet" "project-k8s-snet" {
//   vpc_id     = "${aws_vpc.project-k8s-vpc.id}"
//   cidr_block = "10.0.1.0/24"

//   tags = {
//     Name ="K8s-Master-Server"
//     Managed = "Kubernetes Cluster"
//     Project = "K8s-Demo-ManagedCluster"
//   }

// }

// resource "aws_internet_gateway" "project-k8s-gw" {
//   vpc_id = "${aws_vpc.project-k8s-vpc.id}"

//   tags = {
//     Name ="K8s-Master-Server"
//     Managed = "Kubernetes Cluster"
//     Project = "K8s-Demo-ManagedCluster"
//   }

// }

// resource "aws_route" "project-k8s-rt" {
//   route_table_id = "${aws_vpc.project-k8s-vpc.main_route_table_id}"
//   destination_cidr_block = "0.0.0.0/0"
//   gateway_id = "${aws_internet_gateway.project-k8s-gw.id}"

//   // tags = {
//   //   Name ="K8s-Master-Server"
//   //   Managed = "Kubernetes Cluster"
//   //   Project = "K8s-Demo-ManagedCluster"
//   // }

// }

// resource "aws_security_group" "project-k8s-sg" {
//   name = "${lookup(var.awsprops, "secgroupname")}"
//   description = "${lookup(var.awsprops, "secgroupname")}"
//   vpc_id = "${aws_vpc.project-k8s-vpc.id}"

//   // To Allow SSH Transport
//   ingress {
//     from_port = 0
//     protocol = "tcp"
//     to_port = 65000
//     cidr_blocks = ["0.0.0.0/0"]
//   }

//   egress {
//     from_port       = 0
//     to_port         = 0
//     protocol        = "-1"
//     cidr_blocks     = ["0.0.0.0/0"]
//   }

//   lifecycle {
//     create_before_destroy = true
//   }

//   tags = {
//     Name ="K8s-Master-Server"
//     Managed = "Kubernetes Cluster"
//     Project = "K8s-Demo-ManagedCluster"
//   }

// }

data "aws_subnet" "subnet_id" {
  filter {
    name = "tag:Project"
    values = ["K8s-Demo-ManagedCluster"]
  }
}

data "aws_security_group" "security_group_id" {
  filter {
    name = "tag:Project"
    values = ["K8s-Demo-ManagedCluster"]
  }
}


resource "aws_instance" "project-k8s" {
  ami = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type = "${lookup(var.awsprops, "itype")}"
  // subnet_id = "${aws_subnet.project-k8s-snet.id}"
  subnet_id = "${data.aws_subnet.subnet_id.id}"
  associate_public_ip_address = "${lookup(var.awsprops, "publicip")}"
  key_name = "${var.key_name}"


  vpc_security_group_ids = [
    "${data.aws_security_group.security_group_id.id}"
  ]

  root_block_device {
    delete_on_termination = true
    iops = 150
    volume_size = 50
    volume_type = "gp2"
  }

  tags = {
    Name ="K8s-Master-Server"
    OS = "CentOS"
    Managed = "Kubernetes Cluster"
    Project = "K8s-Demo-ManagedCluster"
  }

  provisioner "file" {
    connection {
      type     = "ssh"
      user     = "centos"
      private_key = "${file("${path.module}/keypad-02032020-us-east-1_New.pem")}"
      host = "${self.public_ip}"
    }

    source = "keypad-02032020-us-east-1_New.pem"
    destination = "/home/centos/.ssh/id_rsa"
  }

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "centos"
      private_key = "${file("${path.module}/keypad-02032020-us-east-1_New.pem")}"
      host = "${self.public_ip}"
    }

    inline = [
      "sudo chown centos:centos /home/centos/.ssh/id_rsa",
      "sudo chmod 600 /home/centos/.ssh/id_rsa",
    ]
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
      "sudo yum install git python-pip ansible -y",
      "echo 'ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no $*' > ssh",
      "chmod +x ssh",
      "GIT_TRACE=1 GIT_SSH='/home/centos/ssh' git clone git@ec2-13-234-37-119.ap-south-1.compute.amazonaws.com:root/kubernetesdeployment.git kubernetes",
    ]
  }

  provisioner "file" {
    connection {
      type     = "ssh"
      user     = "centos"
      private_key = "${file("${path.module}/keypad-02032020-us-east-1_New.pem")}"
      host = "${self.public_ip}"
    }

    source = "hosts_minion"
    destination = "/home/centos/kubernetes/host_minions"
  }

  

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "centos"
      private_key = "${file("${path.module}/keypad-02032020-us-east-1_New.pem")}"
      host = "${self.public_ip}"
    }

    inline = [
      "echo -e '[kubernetes-master-nodes]' > /home/centos/kubernetes/AnsiblePlaybooks/hosts",
      "echo '${self.private_ip}' >> /home/centos/kubernetes/AnsiblePlaybooks/hosts",
      "echo -e '\n' >> /home/centos/kubernetes/AnsiblePlaybooks/hosts",
      "echo -e '[kubernetes-worker-nodes]\n' >> /home/centos/kubernetes/AnsiblePlaybooks/hosts",
      "cat /home/centos/kubernetes/host_minions >> /home/centos/kubernetes/AnsiblePlaybooks/hosts",
      "mv /home/centos/kubernetes/AnsiblePlaybooks/hosts /home/centos/kubernetes/AnsiblePlaybooks/hosts_old",
      "tr -d '\\b\\r' < /home/centos/kubernetes/AnsiblePlaybooks/hosts_old > /home/centos/kubernetes/AnsiblePlaybooks/hosts",
    ]
  }

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      user     = "centos"
      private_key = "${file("${path.module}/keypad-02032020-us-east-1_New.pem")}"
      host = "${self.public_ip}"
    }

    inline = [
      "mv kubernetes/AnsiblePlaybooks/env_variables kubernetes/AnsiblePlaybooks/env_variables_old",
      "sed 's/^ad_addr:.*/ad_addr: ${self.private_ip}/g' kubernetes/AnsiblePlaybooks/env_variables_old > kubernetes/AnsiblePlaybooks/env_variables",
      "cd kubernetes/AnsiblePlaybooks",
      "export ANSIBLE_HOST_KEY_CHECKING=False",
      "ansible-playbook setup_master_node.yml",
      "ansible-playbook setup_worker_nodes.yml",
    ]
  }



  // depends_on = [ aws_security_group.project-k8s-sg ]
}
