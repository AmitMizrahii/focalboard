module "rds" {
  source             = "./modules/rds"
  project_name       = local.project_name
  security_group_ids = [aws_security_group.db-sg.id]
  subnet_ids         = [aws_subnet.private.id, aws_subnet.private2.id]
  credentials        = var.db_credentials
}


