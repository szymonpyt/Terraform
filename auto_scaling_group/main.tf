resource "aws_launch_template" "terraform_launch_template" {
  name = var.template_name

  image_id = var.ami

  instance_type = length(var.instance_types) == 0 ? "t2.micro" : null

  key_name = var.key

  vpc_security_group_ids = [var.sg_id]


}
