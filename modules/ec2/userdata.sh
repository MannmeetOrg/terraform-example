$/bin/bash

pip3.11 install ansible
ansible_pull -i localhost, -U https://github.com/MannmeetOrg/roboshop-ansible.git -e env=${env} -e role_name=${role_name} -e vault_token=${vault_token} 2>&1 | tee /opt/userdata.log