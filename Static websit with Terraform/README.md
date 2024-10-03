

# Static Website Hosting with AWS S3 and CloudFront

This project uses **Terraform** to set up a static website on **Amazon Web Services (AWS)**. It stores the website files in an S3 bucket and uses CloudFront to make the site load faster around the world.

## What You’ll Need

- **AWS Account**: [Sign up here](https://aws.amazon.com/).
- **Terraform**: Install it from [here](https://www.terraform.io/downloads.html).

## How the Code Works

### 1. Setting Up AWS Provider

First, we tell Terraform to use the **AWS Provider**, which allows it to interact with AWS. This bit of code also ensures we are using version 4.0 or higher of the AWS provider.

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}
```

**Explanation**: 
- `terraform` block: Specifies the provider (AWS in this case) and the version required.
- `provider "aws"`: Tells Terraform to use AWS services in the `us-west-2` region.

### 2. Creating the S3 Bucket

Next, we create an **S3 bucket** where our website files will be stored. Think of an S3 bucket as a folder in the cloud.

```hcl
resource "aws_s3_bucket" "static_website_bucket" {
  bucket = "killerboy" # Replace with a unique bucket name
}
```

**Explanation**: 
- `aws_s3_bucket`: This block creates a new S3 bucket. The name "killerboy" should be replaced with something unique, as all S3 bucket names must be unique globally.

### 3. Configuring the S3 Bucket for Website Hosting

We configure the bucket to act as a website by setting a default **index.html** for the homepage and an **error.html** for error pages.

```hcl
resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.static_website_bucket.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }
}
```

**Explanation**: 
- `index_document`: Tells S3 to serve `index.html` as the main page.
- `error_document`: Sets `error.html` as the page shown when an error (like 404) occurs.

### 4. Controlling Object Ownership

We enforce that the **bucket owner** has control over all objects (files) in the bucket.

```hcl
resource "aws_s3_bucket_ownership_controls" "ownership_controls" {
  bucket = aws_s3_bucket.static_website_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}
```

**Explanation**: 
- This ensures that the owner of the bucket (you) controls all files, even if someone else uploads them.

### 5. Allowing Public Access to the Website

Since this is a public website, we need to adjust the **public access settings** to allow people to access the files.

```hcl
resource "aws_s3_bucket_public_access_block" "public_access_block" {
  bucket = aws_s3_bucket.static_website_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}
```

**Explanation**: 
- These settings allow public access to your bucket, which is necessary for a public website.

### 6. Uploading Files to S3

Terraform automatically uploads your website files (HTML, CSS, JavaScript, etc.) to the S3 bucket.

```hcl
resource "aws_s3_object" "website_files" {
  for_each = fileset("C:/Users/RINZEY/Downloads/bootcamp-1-project-1a", "**")

  bucket = aws_s3_bucket.static_website_bucket.bucket
  key    = each.value
  source = "C:/Users/RINZEY/Downloads/bootcamp-1-project-1a/${each.value}"

  content_type = lookup(
    {
      ".html" = "text/html"
      ".css"  = "text/css"
      ".js"   = "application/javascript"
      ".png"  = "image/png"
      ".jpg"  = "image/jpeg"
      ".jpeg" = "image/jpeg"
      ".gif"  = "image/gif"
      ".txt"  = "text/plain"
    },
    (length(regexall("\\.[^.]+$", each.value)) > 0) ? regexall("\\.[^.]+$", each.value)[0] : ".txt",
    "application/octet-stream"
  )
}
```

**Explanation**: 
- `for_each = fileset(...)`: This block loops through all your local files and uploads them to the bucket.
- `content_type`: Automatically sets the correct file type for each uploaded file (HTML, CSS, etc.).

### 7. S3 Bucket Policy to Allow Public Read Access

We define a **bucket policy** that lets anyone on the internet access the files (read-only).

```hcl
resource "aws_s3_bucket_policy" "static_website_policy" {
  bucket = aws_s3_bucket.static_website_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.static_website_bucket.arn}/*"
      }
    ]
  })
}
```

**Explanation**: 
- `Effect = "Allow"`: Grants public read access to all files in the bucket.

### 8. Setting Up CloudFront for Global Delivery

We configure **CloudFront**, which is a content delivery network (CDN) that helps load the website faster across the globe.

```hcl
resource "aws_cloudfront_distribution" "s3_distribution" {
  origin {
    domain_name = aws_s3_bucket.static_website_bucket.bucket_regional_domain_name
    origin_id   = "S3-Origin"
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-Origin"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
```

**Explanation**: 
- `origin`: Points CloudFront to the S3 bucket as the source.
- `viewer_protocol_policy = "redirect-to-https"`: Ensures the site is accessed over HTTPS, which is more secure.

### 9. Output the CloudFront URL

Finally, we output the CloudFront URL where the website will be available.

```hcl
output "cloudfront_url" {
  description = "The CloudFront distribution domain name (URL)"
  value       = aws_cloudfront_distribution.s3_distribution.domain_name
}
```

**Explanation**: 
- This output provides a link to the website once everything is set up.

## Steps to Get Started

1. **Clone the Project**:  
   Download the project to your computer:
   ```bash
   git clone https://github.com/devopsthepracticalway/bootcamp-1-project-1a
   cd bootcamp-1-project-1a
   ```

2. **Set Up AWS Credentials**:  
   Make sure your AWS credentials are set up. Follow [this guide](https://registry.terraform.io/providers/hashicorp/aws/latest/docs#authentication).

3. **Initialize Terraform**:  
   Run this to set up Terraform and download any needed files:
   ```bash
   terraform init
   ```

4. **Plan and Apply**:  
   - Preview the changes:  
     ```bash
     terraform plan
     ```
   - Apply the changes:  
     ```bash
     terraform apply
     ```

5. **Visit Your Website**:  
   After applying, you'll see the CloudFront URL in the terminal. This is where your website is live!

6. **Clean Up (Optional)**:  
   To remove everything (bucket, files, CloudFront), run:
   ```bash
   terraform destroy
   ```

## Troubleshooting

- **S3 Bucket Name Error**: Make sure your bucket name is unique.
- **Permission Issues**: Double-check your AWS credentials.

