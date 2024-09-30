output "subnets" {
  value = tomap(
    "web" = aws_subnets
  )
}