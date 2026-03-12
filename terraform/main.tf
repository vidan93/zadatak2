module "ecs" {
  source = "./ecs_module"

  cluster_name    = var.cluster_name
  sre_task_owner  = var.sre_task_owner
  services        = var.services
  additional_tags = var.additional_tags
}