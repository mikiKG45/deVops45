# --- DB subnet group ---
# Tells RDS which subnets it may live in. We give it PRIVATE subnets only,
# so the database has no route to the internet.
resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.name}-db-subnet-group"
  }
}

# --- Security group for the database ---
resource "aws_security_group" "db" {
  name        = "${var.name}-db-sg"
  description = "Allow PostgreSQL only from the EKS cluster"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.name}-db-sg"
  }
}

# Ingress: PostgreSQL (port 5432) ONLY from the EKS cluster security group.
# source_security_group_id (not a CIDR) is the key: only members of that SG pass.
resource "aws_security_group_rule" "db_ingress_from_cluster" {
  type                     = "ingress"
  from_port                = 5432
  to_port                  = 5432
  protocol                 = "tcp"
  security_group_id        = aws_security_group.db.id
  source_security_group_id = var.allowed_security_group_id
  description              = "PostgreSQL from EKS cluster only"
}

# Egress: allow all outbound (conventional; RDS rarely initiates connections).
resource "aws_security_group_rule" "db_egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  security_group_id = aws_security_group.db.id
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound"
}
