# resource "aws_secretsmanager_secret" "my_secret" {
#   name = local.secret_name
# }

# resource "aws_secretsmanager_secret_version" "my_secret_version" {
#   secret_id     = aws_secretsmanager_secret.my_secret.id
#   secret_string = filebase64("${path.module}/my_encrypted_file.txt")
# }
