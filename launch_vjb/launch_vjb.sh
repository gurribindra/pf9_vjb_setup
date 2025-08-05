#!/bin/bash
#!/bin/bash
#version 0.3
#usage source launch_vjb <vjb_image_name>
#<vjb_image_name> Represents the image name of the desired version such as "vjailbreak-image-0.1.15", "vjailbreak-image-0.2.0", "vjailbreak-image-0.2.1"



#####New Section #####
#For each region collect appropriate information, deploy the VM and add to inventory file
rm inventory.list
tstamp_base=$(date +%a%b%m%H%M)
export tstamp=$(echo  "${tstamp_base,,}")


#Create the CSV file named "locations.csv" as per the structure below
#var_region_name,var_region_id,var_rc_file,var_key_name,var_network_id




while IFS=, read -r var_region_name var_region_id var_rc_file var_key_name var_network_id; do

echo "*****************************************************************************************"
echo "The timestamp will be : $tstamp"
echo "The Region is $var_region_name"
echo "The Region ID is $var_region_id"
echo "The Credential file is stored at rc_files/$var_rc_file"
echo "The public key to be applied is $var_key_name"
echo "The Network on which VJB will be deployed is identified by $var_network_id"
echo "******************************************************************************************"


var_region_id=$var_region_id
var_image_version=$1
echo "Deploying vjb image $1 for $var_region_name"
source rc_files/$var_rc_file
sleep 5s

echo "The auth url is $OS_AUTH_URL"

#Get the appropriate flavor id
var_flavor_id=$(openstack flavor list -f json | jq '.[] | select (.Name | contains("flavor")) | .ID' | tr -d '"')

#Get the appropriate key id
var_key_name=$var_key_name

#Get the network ID
var_network_id=$var_network_id



#Get the image id for vjailbreak image as per version
var_vjb_image=$(openstack image list -f json | jq --arg name "$1" '.[] | select(.Name == $name) | .ID' | tr -d '"')



#Create the instance name
export vjb_instance_name=$(echo -n  "vjb-$var_region_id-$var_image_version-$tstamp")

#Displaying the proposed command
echo "openstack server create \\"
echo    "--flavor $var_flavor_id \\"
echo    "--network $var_network_id \\"
echo    "--image $var_vjb_image \\"
echo    "--user-data cloud-init.yaml\\"
echo    "$vjb_instance_name -f json > $vjb_instance_name.json"

#execuring the command and storing in appropriate json
openstack server create \
--flavor $var_flavor_id \
--network $var_network_id \
--image $var_vjb_image \
--key $var_key_name \
--user-data cloud-init.yaml $vjb_instance_name -f json > vm-status-files/$vjb_instance_name.json


############ Retrieve important information after deployment

export deployed_instance_id=$(cat ./vm-status-files/$vjb_instance_name.json | jq .id | tr -d '"')

echo "The deployed instance with name $vjb_instance_name has instance id of $deployed_instance_id."


instance_status=$(cat -v ./vm-status-files/$vjb_instance_name.json | jq .status | tr -d '"')

#instance_status="ERROR"

echo "The current instance status is $instance_status !"


until [[ "$instance_status" == "ACTIVE"  ||  "instance_status" == "ERROR" ]]; do
        sleep 5s
        instance_status=$(openstack server show $deployed_instance_id -f json |  jq .status | tr -d '"' | tr -d ' ')
        echo "As of $(date) the server with id $deployed_instance_id is at Status = $instance_status!"
done

if [ "$instance_status" == "ACTIVE" ]; then
        instance_address=$(openstack server show $deployed_instance_id -f json | jq .addresses.[].[] | tr -d '"' | tr -d ' ')
        echo $instance_address >> inventory.list
        echo "The instance status  is : $instance_status"
                # Send 10 ping packets and suppress output
                ping -c 10 "$instance_address" > /dev/null
                # Check the exit status of the ping command
                if [ $? -eq 0 ]; then
                        echo "Host $instance_address is reachable."
                        echo "testing if ssh service is responding after 10 Seconds"
                        sleep 10s
                        nc -z -v -w 15 $instance_address 22
                else
                        echo "Host $instance_address is not reachable."
				fi
else
        echo "The instance status is : $instance_status"
fi

done < locations.csv



####Deploy in Ansible
ansible-playbook -i inventory.list -u ubuntu --key-file pf9-admin.key ansible/config-vjb/main.yaml --ssh-common-args='-o StrictHostKeyChecking=no'












