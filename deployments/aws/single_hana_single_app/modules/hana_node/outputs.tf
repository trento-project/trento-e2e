# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: GPL-3.0-or-later

data "aws_instance" "hana" {
  instance_id = aws_instance.hana.id
}

output "hana_ip" {
  value = data.aws_instance.hana.private_ip
}

output "hana_public_ip" {
  value = data.aws_instance.hana.public_ip
}
