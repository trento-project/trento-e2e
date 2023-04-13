#!/bin/bash
sudo su
crm resource param rsc_aws_stonith_PRD_HDB00 set tag ${tag}
crm resource param rsc_ip_PRD_HDB00 set ip ${virtual_ip}
crm resource param rsc_ip_PRD_HDB00 set routing_table ${route_table_id}
crm maintenance off
