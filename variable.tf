variable "region" {
  description = "define aws region"
  type        = string
  default     = "ap-south-1"
}
variable "project" {
  description = "define project name"
  type        = string
  default     = "avincm"
}
variable "env" {
  description = "define project environment"
  type        = string
  default     = "test"
}
variable "owner" {
  description = "define project owner"
  type        = string
  default     = "aravind"
}
variable "ami" {
  description = "define ec2-ami"
  type        = string
  default     = "ami-06f621d90fa29f6d0"

}
variable "instance_type" {
  description = "define instance type of the instance"
  type        = string
  default     = "t2.micro"
}
variable "private_domain" {
  description = "Private domain name"
  type        = string
  default     = "avincm.loc"
}
variable "public_domain" {
  description = "Public domain name"
  type        = string
  default     = "avincm.live"
}
variable "public_zone_id" {
  description = "public_zone_id of avincm.live "
  type        = string
  default     = "Z094318420EHDKUF17GCQ"
}
