output "public_subnet_id" {
  value = aws_subnet.platform_vpc_public_subnets.id
}

output "public_subnet_id_2" {
  value = aws_subnet.platform_vpc_public_subnets_2.id
}

output "private_subnet_id" {
  value = aws_subnet.platform_vpc_private_subnets.id
}

output "private_subnet_id_2" {
  value = aws_subnet.platform_vpc_private_subnets_2.id
}

output "vpc_id" {
  value = aws_vpc.platform_vpc.id
}