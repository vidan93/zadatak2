variable "cluster_name" {
  description = "Cluster name"
  type        = string
}

variable "sre_task_owner" {
  description = "SRE task owner"
  type        = string
}

variable "additional_tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
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
    log_retention_days = optional(number, 7)
  }))

  validation {
    condition = alltrue([
      for k, v in var.services : contains(
        [0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653], 
        v.log_retention_days
      )
    ])
    error_message = "The log_retention_days must be a valid value: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653)."
  }

  validation {
    condition = alltrue([
      for k, v in var.services : contains(
        [256, 512, 1024, 2048, 4096, 8192, 16384], 
        v.task_cpu
      )
    ])
    error_message = "Fargate task_cpu must be a valid value: 256, 512, 1024, 2048, 4096, 8192, or 16384."
  }

  validation {
    condition = alltrue([
      for k, v in var.services : v.desired_count >= 0
    ])
    error_message = "The desired_count must be 0 or greater."
  }

  validation {
    condition = alltrue([
      for k, v in var.services : contains(
        [512, 1024, 2048, 3072, 4096, 5120, 6144, 7168, 8192, 16384, 32768], 
        v.task_memory
      )
    ])
    error_message = "Fargate task_memory must be a valid value: 512, 1024, 2048, 3072, 4096, 5120, 6144, 7168, 8192, 16384, 32768."
  }
}