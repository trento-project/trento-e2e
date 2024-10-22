#!/bin/bash
sudo su
sed -i 's/aws_access_key_id = \(.*\)/aws_access_key_id = ${access_key}/' /root/.aws/config
sed -i 's#aws_secret_access_key = \(.*\)#aws_secret_access_key = ${secret_key}#' /root/.aws/config
crm resource param rsc_aws_stonith_PRD_HDB00 set tag ${tag}
crm resource param rsc_ip_PRD_HDB00 set ip ${virtual_ip}
crm resource param rsc_ip_PRD_HDB00 set routing_table ${route_table_id}
crm maintenance off
