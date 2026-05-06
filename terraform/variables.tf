variable "aws_region" {
  description = "Région AWS"
  type        = string
  default     = "us-east-1"
}

variable "public_key" {
  description = "Clé publique SSH pour se connecter à l'instance"
  type        = string
}
