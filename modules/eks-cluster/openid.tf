###################################################################################################

data "tls_certificate" "issuer" {
  url = aws_eks_cluster.scope.identity[0].oidc[0].issuer
}

###################################################################################################

resource "aws_iam_openid_connect_provider" "openid_provider" {
  url             =   aws_eks_cluster.scope.identity[0].oidc[0].issuer
  client_id_list  = [ "sts.amazonaws.com" ]
  thumbprint_list = [ data.tls_certificate.issuer.certificates[0].sha1_fingerprint ]
}

###################################################################################################

output "openid_connect_provider_id"          { value = aws_iam_openid_connect_provider.openid_provider.id              }
output "openid_connect_provider_arn"         { value = aws_iam_openid_connect_provider.openid_provider.arn             }
output "openid_connect_provider_url"         { value = aws_iam_openid_connect_provider.openid_provider.url             }
output "openid_connect_provider_client_ids"  { value = aws_iam_openid_connect_provider.openid_provider.client_id_list  }
output "openid_connect_provider_thumbprints" { value = aws_iam_openid_connect_provider.openid_provider.thumbprint_list }

###################################################################################################