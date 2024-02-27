output "app_url" {
  value = aws_lb.application_load_balancer.dns_name
}

output "aws_cloudfront_distribution" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}
