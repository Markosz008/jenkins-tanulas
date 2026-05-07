output "db_endpoint" {
  value       = aws_db_instance.mysql_db.endpoint
  description = "Az adatbázis elérhetősége"
}

output "db_name" {
  value = aws_db_instance.mysql_db.db_name
}