terraform {
    backend "s3" {
        bucket = "folding-in-the-cloud"
        key    = "state.tfstate"
        region = "us-east-2"
    }
}

provider "aws" {
  region = "us-east-2"
}
