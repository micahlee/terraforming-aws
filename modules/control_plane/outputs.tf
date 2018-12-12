output "domain" {
  value = "${aws_route53_record.control_plane.name}"
}

output "lb_target_groups" {
  value = [
    "${aws_lb_target_group.atc.name}",
    "${aws_lb_target_group.tsa.name}",
    "${aws_lb_target_group.uaa.name}"
    ]
}

output "subnet_ids" {
  value = ["${aws_subnet.control_plane.*.id}"]
}

output "subnet_gateways" {
  value = ["${data.template_file.subnet_gateways.*.rendered}"]
}

output "subnet_cidrs" {
  value = ["${aws_subnet.control_plane.*.cidr_block}"]
}

output "subnet_availability_zones" {
  value = ["${aws_subnet.control_plane.*.availability_zone}"]
}