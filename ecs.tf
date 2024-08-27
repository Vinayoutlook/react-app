provider "aws" {
  region = "us-east-1"  # Change to your desired region
}

# Create a VPC
resource "aws_vpc" "my_vpc2" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "my-react-vpc"
  }
}

# Create a Subnet
resource "aws_subnet" "my_subnet" {
  vpc_id     = aws_vpc.my_vpc2.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "my-react-subnet"
  }
}

# Create an Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc2.id

  tags = {
    Name = "my-react-igw"
  }
}

# Create a Route Table
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc2.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "my-react-route-table"
  }
}

# Associate the Route Table with the Subnet
resource "aws_route_table_association" "my_route_table_assoc" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route_table.id
}

# Create a Security Group
resource "aws_security_group" "my_sg" {
  vpc_id = aws_vpc.my_vpc2.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "my-react-sg"
  }
}

# Create an ECS Cluster
resource "aws_ecs_cluster" "my_rccluster" {
  name = "my-react-cluster"
}
resource "aws_iam_role" "ecs_execution_role" {
  name = "ecs_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role     = aws_iam_role.ecs_execution_role.name
}

resource "aws_ecs_task_definition" "my_rctask" {
  family                = "my-task"
  network_mode          = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                   = "256"
  memory                = "512"
  execution_role_arn    = aws_iam_role.ecs_execution_role.arn
 
  container_definitions = jsonencode([
    {
      name  = "my-react-container"
      image = "026090536569.dkr.ecr.us-east-1.amazonaws.com/react-app:latest"
      cpu   = 256
      memory = 512
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
          protocol      = "tcp"
        }
      ]
    }
  ])
}

# Create an ECS Service
resource "aws_ecs_service" "my_service" {
  name            = "my-react-service"
  cluster         = aws_ecs_cluster.my_rccluster.id
  task_definition = aws_ecs_task_definition.my_rctask.arn
  launch_type     = "FARGATE"
  desired_count   = 1
  force_new_deployment = true

  network_configuration {
    subnets         = [aws_subnet.my_subnet.id]
    security_groups = [aws_security_group.my_sg.id]
    assign_public_ip = true
  }
}

# Random ID for uniqueness
resource "random_id" "suffix" {
  byte_length = 4
}