data "aws_ami" "latest-ubuntu" {
    most_recent = true
    owners = ["099720109477"] # Canonical
    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
    }

    filter {
      name   = "virtualization-type"
      values = ["hvm"]
  }
}

resource "aws_key_pair" "zr-key" {
 key_name   = "id_ed25519.pub"
 public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII4ukeIMYvkszpd1+DbUhJWKMmeBt7Du4JPryDWCW9ds zrowe007@gmail.com"
}

# Create EC2 Auto Scaling Group
resource "aws_autoscaling_group" "fah_asg" {
  name                      = "fah_asg"
  max_size                  = 3
  min_size                  = 1
  desired_capacity          = 3
  launch_template {
    id      = aws_launch_template.fah_launch_template.id
    version = "$Latest"
  }
  
  vpc_zone_identifier       = [aws_subnet.private_subnet.id]
  health_check_type         = "EC2"
  termination_policies      = ["Default"]
  wait_for_capacity_timeout = "10m"
  target_group_arns         = ["${aws_lb_target_group.ssh_target_group.arn}","${aws_lb_target_group.http_target_group.arn}"]
  tag {
    key = "Name"
    value = "fah_worker"
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }
}

# Define your user data as a variable
variable "user_data_script" {
  type        = string
  description = "User data script"
  default = <<EOF
    #!/bin/bash
    echo "This is user data script"
    # install FAH
    wget https://download.foldingathome.org/releases/public/release/fahclient/debian-testing-64bit/v7.4/fahclient_7.4.4_amd64.deb
    wget https://download.foldingathome.org/releases/public/release/fahcontrol/debian-testing-64bit/v7.4/fahcontrol_7.4.4-1_all.deb
    wget https://download.foldingathome.org/releases/public/release/fahviewer/debian-testing-64bit/v7.4/fahviewer_7.4.4_amd64.deb
    sudo dpkg -i fahclient_7.4.4_amd64.deb
    #sudo dpkg -i fahcontrol_7.4.4_1_all.deb
    #sudo dpkg -i fahviewer_7.4.4_amd64.deb
    sudo /etc/init.d/FAHClient --user=zr2d2 --team=2740 --gpu=false --smp=true
    sudo /etc/init.d/FAHClient start
    EOF
}

# Base64 encode the user data
locals {
  encoded_user_data = base64encode(var.user_data_script)
}

# Create launch template
resource "aws_launch_template" "fah_launch_template" {
  name = "fah_launch_template"
  image_id = "${data.aws_ami.latest-ubuntu.id}"
  instance_type = "a1.xlarge"
  key_name = aws_key_pair.zr-key.key_name
  vpc_security_group_ids = [aws_security_group.fah_security_group.id]
  user_data = local.encoded_user_data
}

# Provisioner to create XML file using local_exec
resource "null_resource" "preload_config" {
  depends_on = [aws_autoscaling_group.fah_asg]

  provisioner "local-exec" {
    command = <<EOT
    echo '<config>
   <!__ Set with your user, passkey, team__>
   <user value="zr2d2"/>
   <passkey value=""/>
   <team value="2740"/>
   <power value="full"/>
   <exit_when_done v='true'/>

   <web_enable v='false'/>
   <disable_viz v='true'/>
   <gui_enabled v='false'/>

   <!__ 16_1 = 15 = 3*5 for decomposition __>
   <slot id='1' type='SMP'> <cpus v='15'/> </slot>

 </config>' > /dev/null #/var/lib/fahclient/configs/config.xml
 #sudo /etc/init.d/FAHClient start
     EOT
   }
 }
