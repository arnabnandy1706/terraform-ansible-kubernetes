variable "key_name" {
  description = "Desired name of AWS key pair"
  default = "keypad-02032020-us-east-1_New"
}

variable "aws_avail_zone" {
  description = "AWS Availability Zone"
  default = "ap-south-1a"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-east-1"
}


variable "aws_amis" {
  default = {
    us-east-1 = "ami-0063927a"
  }
}

variable "awsprops" {
    type = "map"
    default = {
        region = "us-east-1"
        vpc = "vpc-5234832d"
        ami = "ami-0c1bea58988a989155"
        itype = "t2.medium"
        subnet = "subnet-81896c8e"
        publicip = true
        keyname = "myseckey"
        secgroupname = "K8s-SG"
  }
}
