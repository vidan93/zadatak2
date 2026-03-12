cluster_name   = "decenter-ecs-cluster"
sre_task_owner = "Vidan_Drobnjak"

services = {
  "mock-app" = {
    container_name     = "mock-container"
    container_image    = "mock-app:latest"
    task_cpu           = 256
    task_memory        = 512
    app_env            = "dev"
    desired_count      = 2
    subnets            = ["subnet-mock1", "subnet-mock2"]
    security_groups    = ["sg-mock-backend"]
    log_retention_days = 7
  },
  "mock-app2" = {
    container_name     = "mock-container2"
    container_image    = "mock-app2:latest"
    task_cpu           = 256
    task_memory        = 512
    app_env            = "dev"
    desired_count      = 2
    subnets            = ["subnet-mock1", "subnet-mock2"]
    security_groups    = ["sg-mock-backend"]
    log_retention_days = 7
  }
}