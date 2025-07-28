#!/bin/bash
#!/bin/bash
#version 0.2
#usage source launch_vjb <vjb_image_name> <vjb_instance_number>
#<vjb_image_name> Represents the image name of the desired version such as "vjailbreak-image-0.1.15", "vjailbreak-image-0.2.0", "vjailbreak-image-0.2.1"
#<vjb_instance_number> represents the vm number of the vjb in that environment. the number will be consistent across  all regions



#####New Section #####
#For each region collect appropriate information

#For Wilsonville-QA
#identify the region-by
var_region_id=wiv-qa
var_image_version=$1

#Get the appropriate flavor id
var_flavor_id=$(openstack flavor list -f json | jq '.[] | select (.Name | contains("flavor")) | .ID' | tr -d '"')

#Get the appropriate key id
var_key_name="vjb-ansible"

#Get the network ID
var_network_id="7fd8b16a-859d-400a-944e-4afc17adc443"



#Get the image id for vjailbreak image as per version
var_vjb_image=$(openstack image list -f json | jq --arg name "$1" '.[] | select(.Name == $name) | .ID' | tr -d '"')



#Create the instance name
export vjb_instance_name=$(echo -n  "vjb-$var_region-$var_image_version-$2")

#Displaying the proposed command
echo "openstack server create \\"
echo	"--flavor $var_flavor_id \\"
echo	"--network $var_network_id \\"
echo	"--image $var_vjb_image \\"
echo	"--user-data cloud-init.yaml\\"
echo	"$vjb_instance_name -f json > $vjb_instance_name.json"



#execuring the command and storing in appropriate json
openstack server create \
--flavor $var_flavor_id \
--network $var_network_id \
--image $var_vjb_image \
--key $var_key_name \
--user-data cloud-init.yaml $vjb_instance_name -f json > ./vm-status-files/$vjb_instance_name.json


############ Retrieve important information after deployment 

deployed_instance_id=$(cat ./vm-status-files/$vjb_instance_names.json | jq .id | tr -d '"')

instance_status=$(cat ./vm-status-files/$vjb_instance_names.json | jq .status | tr -d '"')

while [ $instance_status -ne  "ACTIVE" ] || [$instance_status -ne "ERROR" ] ; do
	sleep 5s
	instance_status=$(openstack server show $deployed_instance_id |  jq .status | tr -d '"')
done

if [$instance_status -eq "ACTIVE"];
	instance_address=$(openstack server show $deployed_instance_id -f json | jq .addresses.[].[] | tr -d '"')
	echo -n $instance_address >> inventory.list
	echo "The instance status  is : $instance_status"
		# Send a single ping packet and suppress output
		ping -c 1 "$instance_address" > /dev/null
		# Check the exit status of the ping command
		if [ $? -eq 0 ]; then
  			echo "Host $instance_address is reachable."
		else
  			echo "Host $instance_address is not reachable."
		fi
else
	echo "The instance status is : $instance_status"
fi


#Configure the created vjb instances

ansible-playbook -i 











































