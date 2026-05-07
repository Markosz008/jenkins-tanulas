output "db_endpoint" {
  value       = aws_db_instance.mysql_db.endpoint
  description = "Az adatbázis elérhetősége"
}

output "db_name" {
  value = aws_db_instance.mysql_db.db_name
}
output "alb_dns_name" {
  value = aws_lb.web_alb.dns_name
  description = "Ezen a címen éred el a weboldalt"
}