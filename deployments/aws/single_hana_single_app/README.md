# How to use

This deployment consists on a single HANA and single ASCS/PAS deployment. Even though it was not strictly needed, the ASCS/PAS machine connects to a NFS share where `/sapmnt/` and `/usr/sap/SID/SYS` folders are stored. This means that a EFS backup system is needed together with the 2 machine snapshots.

This adds some additional steps to the deployment. In order to deploy follow the next steps:
- Create a EFS item from the initial EFS backup. The easiest way to do so is to use the AWS web console. Using this option, go to the `AWS Backup` panel, and from there restore the EFS backup in a new EFS system using the `Restore to a new file system` option.
- Import the created EFS into terraform. For that run: `terraform import module.app_node.aws_efs_file_system.app-efs arn:aws:elasticfilesystem:eu-central-1:xxx:file-system/fs-xxxx` with your AWS account ID and the created file system ID.
- Run terraform normally

Be aware that once the environment is destroyed, the EFS entry created manually is destroyed as it was imported to the terraform state.