#!/bin/bash
#!/bin/bash
#version 0.2
#usage source launch_vjb <vjb_image_name> <vjb_instance_number>
#<vjb_image_name> Represents the image name of the desired version such as "vjailbreak-image-0.1.15", "vjailbreak-image-0.2.0", "vjailbreak-image-0.2.1"
#<vjb_instance_number> represents the vm number of the vjb in that environment. the number will be consistent across  all regions



#####New Section #####
#For each region collect appropriate information, deploy the VM and add to inventory file
rm inventory.list


#For Wilsonville-QA
#identify the region-by
var_region_id=wiv-qa
var_image_version=$1
source rc_files/qa-wilsonville.rc
sleep 5s
echo "The auth url is $OS_AUTH_URL"

#Get the appropriate flavor id
var_flavor_id=$(openstack flavor list -f json | jq '.[] | select (.Name | contains("flavor")) | .ID' | tr -d '"')

#Get the appropriate key id
var_key_name="vjb-ansible"

#Get the network ID
var_network_id="7fd8b16a-859d-400a-944e-4afc17adc443"



#Get the image id for vjailbreak image as per version
var_vjb_image=$(openstack image list -f json | jq --arg name "$1" '.[] | select(.Name == $name) | .ID' | tr -d '"')



#Create the instance name
export vjb_instance_name=$(echo -n  "vjb-$var_region_id-$var_image_version-$2")

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
--user-data cloud-init.yaml $vjb_instance_name -f json > vm-status-files/$vjb_instance_name.json


############ Retrieve important information after deployment 

export deployed_instance_id=$(cat ./vm-status-files/$vjb_instance_name.json | jq .id | tr -d '"')

echo "The deployed instance with name $vjb_instance_name has instance id of $deployed_instance_id."


instance_status=$(cat -v ./vm-status-files/$vjb_instance_name.json | jq .status | tr -d '"')

#instance_status="ERROR"

echo "The current instance status is $instance_status !"


until [[ "$instance_status" == "ACTIVE" || "instance_status" == "ERROR" ]]; do
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





#For Milford-PROD
#identify the region-by
var_region_id=mif-prod
var_image_version=$1
source rc_files/mif_prod_service.rc
sleep 5s
echo "The auth url is $OS_AUTH_URL"

#Get the appropriate flavor id
var_flavor_id=$(openstack flavor list -f json | jq '.[] | select (.Name | contains("flavor")) | .ID' | tr -d '"')

#Get the appropriate key id
var_key_name="vjb-ansible"

#Get the network ID
var_network_id="7ced1c2a-617c-4b77-989d-5690a040ce75"

#Get the image id for vjailbreak image as per version
var_vjb_image=$(openstack image list -f json | jq --arg name "$1" '.[] | select(.Name == $name) | .ID' | tr -d '"')

#Create the instance name
export vjb_instance_name=$(echo -n  "vjb-$var_region_id-$var_image_version-$2")

#executing the command and storing in appropriate json
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
until [[ "$instance_status" == "ACTIVE" || "instance_status" == "ERROR" ]]; do
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

################################################

#For Wilsonville-PROD
#identify the region-by
var_region_id=wiv-prod
var_image_version=$1
source rc_files/wiv_prod_service.rc
sleep 5s
echo "The auth url is $OS_AUTH_URL"

#Get the appropriate flavor id
var_flavor_id=$(openstack flavor list -f json | jq '.[] | select (.Name | contains("flavor")) | .ID' | tr -d '"')

#Get the appropriate key id
var_key_name="vjb-ansible"

#Get the network ID
var_network_id="8283d6ca-1c3a-45af-9c74-8308b381c148"

#Get the image id for vjailbreak image as per version
var_vjb_image=$(openstack image list -f json | jq --arg name "$1" '.[] | select(.Name == $name) | .ID' | tr -d '"')

#Create the instance name
export vjb_instance_name=$(echo -n  "vjb-$var_region_id-$var_image_version-$2")

#executing the command and storing in appropriate json
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
until [[ "$instance_status" == "ACTIVE" || "instance_status" == "ERROR" ]]; do
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




##########################Configure all instances after deployment
ansible-playbook -i inventory.list -u ubuntu --key-file pf9-admin.key ansible/config-vjb/main.yaml --ssh-common-args='-o StrictHostKeyChecking=no'








































