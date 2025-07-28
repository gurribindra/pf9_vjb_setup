export deployed_instance_id=$(cat ./vm-status-files/$vjb_instance_name.json | jq .id | tr -d '"')

echo "The deployed instance with name $vjb_instance_name has instance id of $deployed_instance_id."


instance_status=$(cat -v ./vm-status-files/$vjb_instance_name.json | jq .status | tr -d '"')

instance_status="ERROR"

echo "The current instance status is $instance_status !"


until [[ "$instance_status" == "ACTIVE" || "instance_status" == "ERROR" ]]; do
	echo "Testing Special characters "
	if [[ "$instance_status" =~ [^a-zA-Z0-9[:space:]] ]]; then
  		echo "The string contains special characters."
	else
  		echo "The string does not contain special characters."
	fi
        sleep 5s
        instance_status=$(openstack server show $deployed_instance_id -f json |  jq .status | tr -d '"' | tr -d ' ')
        echo "As of $(date) the server with id $deployed_instance_id is at Status = $instance_status!"
done

if [ "$instance_status" == "ACTIVE" ]; then
        instance_address=$(openstack server show $deployed_instance_id -f json | jq .addresses.[].[] | tr -d '"' | tr -d ' ')
        echo $instance_address >> inventory.list
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


ansible-playbook -i inventory.list -u ubuntu --key-file pf9-admin.key ansible/config-vjb/main.yaml
