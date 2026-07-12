aws_region = "us-east-1"
cidr_block = "10.0.0.0/16"
public_subnet = {
  az_1 = {
    cidr_block        = "10.0.1.0/24"
    availability_zone = "us-east-1a"
  }

  az_2 = {
    cidr_block        = "10.0.2.0/24"
    availability_zone = "us-east-1b"
  }
}

private_backend_subnet = {
  az_1 = {
    cidr_block        = "10.0.10.0/24"
    availability_zone = "us-east-1a"
  }

  az_2 = {
    cidr_block        = "10.0.20.0/24"
    availability_zone = "us-east-1b"
  }
}

private_db_subnet = {
  az_1 = {
    cidr_block        = "10.0.30.0/24"
    availability_zone = "us-east-1a"
  }

  az_2 = {
    cidr_block        = "10.0.40.0/24"
    availability_zone = "us-east-1b"
  }
}

tags = {
  Name        = "tf-aws-project"
  CreatedBy   = "terraform"
  ManagedBy   = "terraform"
  Environment = "dev"
}

domain_name = "shyamdevops.online"

db_name     = "postgres"
db_username = "petclinic"
