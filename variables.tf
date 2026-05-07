variable "db_password" {
  description = "Az RDS adatbázis admin jelszava"
  type        = string
  sensitive   = true
  default     = "NagyonTitkos1234" # Ezt később a Jenkinsben is megadhatod!
}