terraform {
    backend "s3" {
        bucket = "tf-state-3451234"
        key    = "development/terraform_state"
        region = "us-east-2"
    }
}