output "cluster_name" {
  description = "Cluster name"
  value       = aws_ecs_cluster.this.name
}

output "service_names" {
  description = "Service names"
  value       = [for service in aws_ecs_service.this : service.name]
}