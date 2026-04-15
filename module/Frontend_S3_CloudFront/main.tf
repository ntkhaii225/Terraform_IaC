# =============================================================================
# Frontend S3 + CloudFront Module
# Host React SPA trên S3, phân phối qua CloudFront CDN
# CloudFront có 2 origins: S3 (frontend) + ALB (/api/*)
# =============================================================================

# -----------------------------------------------------------------------------
# Data Source: Route53 Zone
# -----------------------------------------------------------------------------
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# -----------------------------------------------------------------------------
# S3 Bucket - Lưu file build React (dist/)
# -----------------------------------------------------------------------------
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-${var.environment}"

  tags = {
    Name        = "${var.project_name}-frontend-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# -----------------------------------------------------------------------------
# CloudFront Origin Access Control (OAC)
# Xác thực CloudFront khi lấy dữ liệu từ S3 (thay thế OAI cũ)
# -----------------------------------------------------------------------------
resource "aws_cloudfront_origin_access_control" "s3" {
  name                              = "${var.project_name}-frontend-oac"
  description                       = "OAC for Frontend S3 bucket"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# -----------------------------------------------------------------------------
# S3 Bucket Policy - Chỉ cho phép CloudFront OAC đọc
# -----------------------------------------------------------------------------
resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = { Service = "cloudfront.amazonaws.com" }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.frontend.arn
          }
        }
      }
    ]
  })
}

# -----------------------------------------------------------------------------
# CloudFront Function - SPA Routing
# Rewrite tất cả non-file paths về /index.html cho React Router
# Chỉ áp dụng cho S3 origin, không ảnh hưởng /api/*
# -----------------------------------------------------------------------------
resource "aws_cloudfront_function" "spa_rewrite" {
  name    = "${var.project_name}-spa-rewrite"
  runtime = "cloudfront-js-2.0"
  comment = "Rewrite SPA routes to /index.html"

  code = <<-EOF
    function handler(event) {
      var request = event.request;
      var uri = request.uri;

      // Nếu URI chứa dấu chấm (file thực: .js, .css, .png, ...)
      // thì trả về file đó từ S3
      if (uri.includes('.')) {
        return request;
      }

      // Nếu không có extension (SPA route: /dashboard, /login, ...)
      // rewrite về /index.html để React Router xử lý
      request.uri = '/index.html';
      return request;
    }
  EOF
}

# -----------------------------------------------------------------------------
# CloudFront Distribution - 2 Origins (S3 + ALB)
# -----------------------------------------------------------------------------
resource "aws_cloudfront_distribution" "frontend" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  aliases             = [var.domain_name]
  comment             = "${var.project_name} Frontend Distribution"

  # --- Origin 1: S3 (Frontend static files) ---
  origin {
    domain_name              = aws_s3_bucket.frontend.bucket_regional_domain_name
    origin_id                = "S3-Frontend"
    origin_access_control_id = aws_cloudfront_origin_access_control.s3.id
  }

  # --- Origin 2: ALB (Backend API) ---
  origin {
    domain_name = var.alb_domain_name # alb.fuec.site (custom domain cho ALB)
    origin_id   = "ALB-Backend"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }

  # --- Default Behavior: S3 (Frontend) ---
  default_cache_behavior {
    target_origin_id       = "S3-Frontend"
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # Cache Policy: CachingOptimized (AWS Managed)
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    # CloudFront Function cho SPA routing
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.spa_rewrite.arn
    }
  }

  # --- /api/* Behavior: ALB (Backend) ---
  ordered_cache_behavior {
    path_pattern           = "/api/*"
    target_origin_id       = "ALB-Backend"
    allowed_methods        = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods         = ["GET", "HEAD"]
    viewer_protocol_policy = "redirect-to-https"
    compress               = true

    # Cache Policy: CachingDisabled (không cache API responses)
    cache_policy_id = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad"

    # Origin Request Policy: AllViewerExceptHostHeader
    # Forward tất cả headers, query strings, cookies (trừ Host)
    origin_request_policy_id = "b689b0a8-53d0-40ab-baf2-68738e2966ac"
  }

  # --- SSL Certificate ---
  viewer_certificate {
    acm_certificate_arn      = var.acm_certificate_arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  # --- Không giới hạn vùng địa lý ---
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name        = "${var.project_name}-frontend-distribution"
    Environment = var.environment
  }
}

# -----------------------------------------------------------------------------
# Route 53: fuec.site → CloudFront
# -----------------------------------------------------------------------------
resource "aws_route53_record" "frontend" {
  zone_id         = data.aws_route53_zone.main.zone_id
  name            = var.domain_name
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = aws_cloudfront_distribution.frontend.domain_name
    zone_id                = aws_cloudfront_distribution.frontend.hosted_zone_id
    evaluate_target_health = false
  }
}

# Route 53: alb.fuec.site → ALB (cho CloudFront origin HTTPS validation)
resource "aws_route53_record" "alb" {
  zone_id         = data.aws_route53_zone.main.zone_id
  name            = "alb.${var.domain_name}"
  type            = "A"
  allow_overwrite = true

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_zone_id
    evaluate_target_health = true
  }
}
