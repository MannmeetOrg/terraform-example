# AWS ASG Security Group
resource "aws_security_group" "main" {
  name        = "${var.name}-${var.env}-sg"
  description = "${var.name}-${var.env}-sg"
  vpc_id      = var.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = var.bastion_nodes
  }

  ingress {
    from_port   = var.allow_port
    to_port     = var.allow_port
    protocol    = "TCP"
    cidr_blocks = var.allow_sg_cidr
  }

  tags = {
    Name = "${var.name}-${var.env}-sg"
  }
}

# AWS Launch Template for Instance
resource "aws_launch_template" "main" {
  name = "${var.name}-${var.env}-lt"
  image_id = data.aws_ami.rhel9.image_id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.main.id]
  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    env         = var.env
    role_name   = var.name
    vault_token = var.vault_token
  }))

  tags = {
    Name = "${var.name}-${var.env}-lt"
  }
}

# AWS Auto Scaling Group
resource "aws_autoscaling_group" "main" {
  name                = "${var.name}-${var.env}-asg"
  desired_capacity    = var.capacity["desired"]
  max_size            = var.capacity["max"]
  min_size            = var.capacity["min"]
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = [aws_lb_target_group.main.arn]
  # load_balancers      = [aws_lb.main.*.arn[count.index]]

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = "${var.name}-${var.env}"
  }
}


resource "aws_security_group" "load-balancer" {
  name        = "${var.name}-${var.env}-alb-sg"
  description = "${var.name}-${var.env}-alb-sg"
  vpc_id      = var.vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "TCP"
    cidr_blocks      = var.allow_lb_sg_cidr
  }

  ingress {
    from_port        = 443
    to_port          = 443
    protocol         = "TCP"
    cidr_blocks      = var.allow_lb_sg_cidr
  }

  tags = {
    Name = "${var.name}-${var.env}-alb-sg"
  }
}

resource "aws_lb" "main" {
  count              = var.asg ? 1 : 0
  name               = "${var.name}-${var.env}"
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load-balancer.*.id[count.index]]
  subnets            = var.lb_subnet_ids

  tags = {
    Environment = "${var.name}-${var.env}"
  }
}


resource "aws_lb_target_group" "main" {
  count    = var.asg ? 1 : 0
  name     = "${var.name}-${var.env}"
  port     = var.allow_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled               = true
    healthy_threshold     = 2
    unhealthy_threshold   = 2
    interval              = 5
    path                  = "/health"
    timeout               = 3
  }
}

resource "aws_lb_listener" "internal-http" {
  count             = var.internal ? 1 : 0
  load_balancer_arn = aws_lb.main.*.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.*.arn[count.index]
  }
}
resource "aws_lb_listener" "public-http" {
  count             = var.internal ? 0 : 1
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.*.arn[count.index]
  }
}

resource "aws_lb_listener" "public-http" {
  count             = var.internal ? 0 : 1
  load_balancer_arn = aws_lb.main.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_route53_record" "lb" {
  count   = var.asg ? 1 : 0
  zone_id = var.zone_id
  name    = "${var.name}-${var.env}"
  type    = "CNAME"
  ttl     = 10
  records = [aws_lb.main.*.dns_name[count.index]]
}
