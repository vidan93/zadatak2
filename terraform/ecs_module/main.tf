data "aws_region" "current" {}

locals {
  common_tags = merge(
    { SRE_TASK = var.sre_task_owner },
    var.additional_tags
  )
}

### ECS CLUSTER ###
resource "aws_ecs_cluster" "this" {
  name = var.cluster_name
  tags = local.common_tags
}

### CLOUDWATCH LOG GROUP ###
resource "aws_cloudwatch_log_group" "this" {
  for_each          = var.services
  name              = "/ecs/${var.cluster_name}/${each.value.container_name}"
  retention_in_days = each.value.log_retention_days
  tags              = local.common_tags
}

### IAM ROLE DEFINITIONS ###
data "aws_iam_policy_document" "ecs_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

### TASK EXECUTION ROLE ###
resource "aws_iam_role" "ecs_task_execution_role" {
  for_each           = var.services
  name               = "${var.cluster_name}-${each.key}-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
  tags               = local.common_tags
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_policy" {
  for_each   = var.services
  role       = aws_iam_role.ecs_task_execution_role[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

### TASK ROLE ###
resource "aws_iam_role" "ecs_task_role" {
  for_each           = var.services
  name               = "${var.cluster_name}-${each.key}-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_assume_role.json
  tags               = local.common_tags
}

### ECS TASK DEFINITION ###
resource "aws_ecs_task_definition" "this" {
  for_each                 = var.services
  family                   = "${var.cluster_name}-${each.key}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = each.value.task_cpu
  memory                   = each.value.task_memory
  execution_role_arn       = aws_iam_role.ecs_task_execution_role[each.key].arn
  task_role_arn            = aws_iam_role.ecs_task_role[each.key].arn
  tags                     = local.common_tags

  container_definitions = jsonencode([
    {
      name      = each.value.container_name
      image     = each.value.container_image
      cpu       = each.value.task_cpu
      memory    = each.value.task_memory
      essential = true
      environment = [
        {
          name  = "APP_ENV"
          value = each.value.app_env
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.this[each.key].name
          "awslogs-region"        = data.aws_region.current.name # DODATO: Dinamičko čitanje regiona
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

### ECS SERVICE ###
resource "aws_ecs_service" "this" {
  for_each        = var.services
  name            = each.key
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this[each.key].arn
  desired_count   = each.value.desired_count
  launch_type     = "FARGATE"
  tags            = local.common_tags

  network_configuration {
    subnets          = each.value.subnets
    security_groups  = each.value.security_groups
    assign_public_ip = false
  }
}