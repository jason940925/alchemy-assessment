###################################################################################################

data "aws_region" "scope" {}

###################################################################################################

output "region" { value = data.aws_region.scope.name }

###################################################################################################
