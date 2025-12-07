variable "location" {
  type    = string
  default = "South India"
}

variable "resource_group_name" {
  type = string
}

variable "clusters" {
  type = map(object({
    name = string
  }))
}
