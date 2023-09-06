output "nat_gateway_public_ip" {
  value = aws_nat_gateway.nat_igw.public_ip

}
output "bastion_public_ip" {
  value = aws_instance.bastion.public_ip

}
output "bastion_private_ip" {
  value = aws_instance.bastion.private_ip

}
output "bastion_srv_availability_zone" {
  value = aws_instance.bastion.availability_zone

}
output "frontend_public_ip" {
  value = aws_instance.frontend.public_ip

}
output "frontend_private_ip" {
  value = aws_instance.frontend.private_ip

}
output "frontend_srv_availability_zone" {
  value = aws_instance.frontend.availability_zone

}
output "backend_srv_availability_zone" {
  value = aws_instance.backend.availability_zone

}
output "bastion_srv_domain_Name" {
  value = aws_route53_record.bastion_public_record.name

}
output "frontend_srv_domain_Name" {
  value = aws_route53_record.frontend_public_record.name

}