## Find the current region 
data "aws_region" "current" {}

## Find the current identity for the container session 
data "aws_caller_identity" "current" {}