{*
 SPDX-FileCopyrightText: SUSE LLC
 SPDX-License-Identifier: Apache-2.0
*}

#!/bin/bash
sudo SUSEConnect -r ${license_key} -e ${license_email}
sudo SUSEConnect -p sle-module-basesystem/${sles_version}/x86_64
sudo SUSEConnect -p PackageHub/${sles_version}/x86_64
sudo SUSEConnect -p sle-module-containers/${sles_version}/x86_64
