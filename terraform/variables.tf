variable "cluster_name" {
  description = "Cluster name"
  type        = string
}

variable "sre_task_owner" {
  description = "SRE task owner"
  type        = string
}

variable "services" {
  description = "ECS services map"
  type = map(object({
    container_name     = string
    container_image    = string
    task_cpu           = number
    task_memory        = number
    app_env            = string
    desired_count      = number
    subnets            = list(string)
    security_groups    = list(string)
    log_retention_days = number
  }))
}

variable "additional_tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}