# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: Apache-2.0

output "cluster_profile_name" {
  value = aws_iam_instance_profile.cluster_role_profile.*.name
}
