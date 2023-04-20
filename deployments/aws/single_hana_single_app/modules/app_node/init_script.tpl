#!/bin/bash
rm -rf /tmp/sap_efs
mkdir /tmp/sap_efs
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${efs_dns}:/ /tmp/sap_efs
backup_folder=`ls /tmp/sap_efs`
sed -E -i "s,fs-\S*/sapmnt,${efs_dns}://$backup_folder/sapmnt,g" /etc/fstab
sed -E -i "s,fs-\S*/usrsapsys,${efs_dns}://$backup_folder/usrsapsys,g" /etc/fstab

mount -av

su -c 'sapcontrol -nr 00 -function StartService HA1' - ha1adm
su -c 'sapcontrol -nr 00 -function WaitforServiceStarted 2700 0' - ha1adm
su -c 'sapcontrol -nr 00 -function StartWait 2700 0' - ha1adm
su -c 'sapcontrol -nr 01 -function StartService HA1' - ha1adm
su -c 'sapcontrol -nr 01 -function WaitforServiceStarted 2700 0' - ha1adm
su -c 'sapcontrol -nr 01 -function StartWait 2700 0' - ha1adm
while [ $? -ne 0 ]
do
    su -c 'sapcontrol -nr 01 -function StopWait 2700 0' - ha1adm
    su -c 'sapcontrol -nr 01 -function StartWait 2700 0' - ha1adm
done
    
