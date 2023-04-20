output "cluster_profile_name" {
  value = aws_iam_instance_profile.cluster_role_profile.*.name
}
