#!/bin/bash

FILE="/var/lib/jenkins/jenkins.model.JenkinsLocationConfiguration.xml" # To be replaced it with something dynamic

# Check if the file exists

if [ "$#" -ne 1 ]; then
    JENKINS_SERVER_NAME=Jenkins-server
else
	JENKINS_SERVER_NAME="$1"
fi

if [ -e "$FILE" ]; then

    echo -e "\nThe File $FILE exists."

	# Retrieve public IP addresses and instance IDs for running instances
	NEW_IP=`aws ec2 describe-instances --filters "Name=tag:Name,Values=$JENKINS_SERVER_NAME" --query "Reservations[*].Instances[?State.Name=='running'].PublicIpAddress" --output text`
	JENKINS_INSTANCE_ID=`aws ec2 describe-instances --filters "Name=tag:Name,Values=$JENKINS_SERVER_NAME" --query "Reservations[*].Instances[?State.Name=='running'].InstanceId" --output text`

	# Check if instances_info is empty
	if [[ -z "$NEW_IP" ]]; then
		echo -e "\nNo running instances found with the name $JENKINS_SERVER_NAME."
		echo -e "\n"
		exit 1
	else 	
		
		# IP extraction
		OLD_IP=$(grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' "$FILE")
		
		if [ -n "$OLD_IP" ]; then

			# Display results
			echo -e "\n#################### INSTANCE INFORMATION ################"
			echo "Jenkins InstanceId: $JENKINS_INSTANCE_ID"
			echo "Old Jenkins Server IP Address: $OLD_IP"
			echo "New Jenkins Server IP Address: $NEW_IP"
			
			# Change the OLD_IP by the NEW_IP
			#sudo sed -i "s/$OLD_URL/$NEW_URL/g" "$FILE"
			
			grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' "$FILE" | while read -r ip; do 
				sudo sed -i "s/$ip/$NEW_IP/g" "$FILE" 
			done
			
			# Display the new file updated
			echo -e "\n#################### New version of the file #####################"
			sudo cat $FILE
			echo ""
			
						# Restart the service
			echo -e "\n#################### Restarting Jenkins Server #####################"
			echo "Restart Jenkins Service, please wait a moment ...."
			sudo systemctl restart jenkins.service
			sleep 5 
			sudo systemctl status jenkins | grep running
			echo -e "\nDone...................."
			echo -e "\n"
		
		else
			echo "No IP address found in the file $FILE."
			exit 1
		fi
		
	fi
else
    echo -e "\nThe file $FILE does not exist."
fi