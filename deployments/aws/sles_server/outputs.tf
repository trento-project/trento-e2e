# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: GPL-3.0-or-later



output "machines" {
  value = [for instance in aws_instance.server : ({
    name       = instance.tags_all["Name"]
    private_ip = instance.private_ip
    public_ip  = instance.public_ip
  })]
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}
