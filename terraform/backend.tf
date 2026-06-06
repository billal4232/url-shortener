terraform{
  backend "s3" {
    bucket         = "limonlab-terraform-state"
    key            = "url-shortener/terraform.tfstate"
    region         = "eu-north-1"
    use_lockfile   = true
    encrypt        = true
    profile        = "limonlab"
  }
}