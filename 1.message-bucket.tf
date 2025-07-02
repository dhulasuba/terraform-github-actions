#random_string with prefix "name" to generate a unique bucket name
#need bucket prefix to avoid conflicts
resource "random_pet" "name" {
  prefix = "messages-bucket-"
}

resource "aws_s3_bucket" "messages" {
  bucket = "messages-bucket-${random_pet.name.id}"
  force_destroy = true

  tags = {
    Name        = "Messages Bucket"
    Environment = "Production"
  }
}
