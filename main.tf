locals {
  project_name = "focalboard"

  common_tags = {
    Creator = "1337"
    project = local.project_name
  }
}

# craete a vpc -done
# create a private subnet even two - done
# create rds with postgres engine - done
# push the image to ecr - done
# craete ecs with FARGATE and EBS to override the config file
