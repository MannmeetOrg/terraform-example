output "subnets" {
  value = tomap({
    "web"    = aws_subnet.web_subnet.*.id
    "app"    = aws_subnet.app_subnet.*.id
    "db"     = aws_subnet.db_subnet.*.id
    "public" = aws_subnet.public_subnet.*.id
  })
}

output "vpc_id" {
  value = aws_vpc.main.id
}