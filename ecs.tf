resource "aws_ecs_cluster" "my_cluster" {
  name = "my-cluster"
}

resource "aws_ecs_task_definition" "my_task" {
  family                = "my-task"
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu    = "256"
  memory = "512"
  container_definitions = jsonencode([{
    name      = "react-app"
    image     = "026090536569.dkr.ecr.us-east-1.amazonaws.com/react-app"
    cpu       = 256
    memory    = 512
    essential = true
    portMappings = [
      {
        containerPort = 8080
        hostPort      = 80
        protocol      = "tcp"
      }
    ]
  }])

  execution_role_arn = aws_iam_role.ecs_execution.arn
  task_role_arn      = aws_iam_role.ecs_task.arn
}

resource "aws_ecs_service" "my_service" {
  name            = "my-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_task.arn
  desired_count   = 1 #this will set up reqired number of container
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.subnet_a.id]
    assign_public_ip  = true
    security_groups   = [aws_security_group.ecs_sg.id]
  }
}