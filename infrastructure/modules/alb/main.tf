resource "aws_lb" "app_alb" {
  name               = substr("${var.project_name}-${var.environment}-alb", 0, 32)
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg_id]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false

  tags = {
    Name        = "${var.project_name}-${var.environment}-alb"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_lb_target_group" "app_tg" {
  name        = substr("${var.project_name}-${var.environment}-tg", 0, 32)
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-tg"
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "app_attachment" {
  target_group_arn = aws_lb_target_group.app_tg.arn
  target_id        = var.app_instance_id
  port             = 80
}

# --- Grafana (3000) ---
resource "aws_lb_target_group" "grafana_tg" {
  name        = substr("${var.project_name}-${var.environment}-grafana-tg", 0, 32)
  port        = 3000
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/api/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb_listener" "grafana_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 3000
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.grafana_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "grafana_attachment" {
  target_group_arn = aws_lb_target_group.grafana_tg.arn
  target_id        = var.app_instance_id
  port             = 3000
}

# --- Prometheus (9090) ---
resource "aws_lb_target_group" "prometheus_tg" {
  name        = substr("${var.project_name}-${var.environment}-prom-tg", 0, 32)
  port        = 9090
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/-/healthy"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb_listener" "prometheus_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 9090
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.prometheus_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "prometheus_attachment" {
  target_group_arn = aws_lb_target_group.prometheus_tg.arn
  target_id        = var.app_instance_id
  port             = 9090
}

# --- Alertmanager (9093) ---
resource "aws_lb_target_group" "alertmanager_tg" {
  name        = substr("${var.project_name}-${var.environment}-alert-tg", 0, 32)
  port        = 9093
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/-/healthy"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb_listener" "alertmanager_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 9093
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alertmanager_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "alertmanager_attachment" {
  target_group_arn = aws_lb_target_group.alertmanager_tg.arn
  target_id        = var.app_instance_id
  port             = 9093
}

# --- Node Exporter (9100) ---
resource "aws_lb_target_group" "node_exporter_tg" {
  name        = substr("${var.project_name}-${var.environment}-node-tg", 0, 32)
  port        = 9100
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

resource "aws_lb_listener" "node_exporter_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 9100
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.node_exporter_tg.arn
  }
}

resource "aws_lb_target_group_attachment" "node_exporter_attachment" {
  target_group_arn = aws_lb_target_group.node_exporter_tg.arn
  target_id        = var.app_instance_id
  port             = 9100
}
