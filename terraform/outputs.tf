output "ecs_cluster_name" {
  description = "Cluster name"
  value       = module.ecs.cluster_name
}

output "ecs_service_names" {
  description = "Service names"
  value       = module.ecs.service_names
}