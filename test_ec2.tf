data "aws_ssm_parameter" "amazon_linux_2023_ami" {
  provider = aws.target

  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "env_control_test" {
  provider = aws.target

  ami           = data.aws_ssm_parameter.amazon_linux_2023_ami.value
  instance_type = "t3.micro"

  tags = {
    Name       = "EnvControl-Test"
    EnvControl = "True"
    ManagedBy  = "Terraform"
  }
}