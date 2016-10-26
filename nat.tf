variable "nat_ami_map" {
  type = "map"

  default = {
    us-east-1      = "ami-303b1458"
    us-west-1      = "ami-7da94839"
    us-west-2      = "ami-69ae8259"
    eu-west-1      = "ami-6975eb1e"
    eu-central-1   = "ami-46073a5b"
    ap-southeast-1 = "ami-b49dace6"
    ap-northeast-1 = "ami-03cf3903"
    ap-southeast-2 = "ami-e7ee9edd"
    sa-east-1      = "ami-fbfa41e6"
  }
}

resource "aws_instance" "nat" {
  depends_on             = ["aws_security_group.nat_security_group", "aws_subnet.public_subnets"]
  ami                    = "${lookup(var.nat_ami_map, var.region)}"
  instance_type          = "t2.medium"
  key_name               = "${var.nat_key_pair_name}"
  vpc_security_group_ids = ["${aws_security_group.nat_security_group.id}"]
  source_dest_check      = false
  subnet_id              = "${aws_subnet.public_subnets.0.id}"

  tags {
    Name = "${var.env_name}-nat"
  }
}

resource "aws_eip" "nat_eip" {
  instance = "${aws_instance.nat.id}"
  vpc      = true
}
