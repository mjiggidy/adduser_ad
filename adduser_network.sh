#!/bin/bash

# Editable things
group_name="Domain Users" # Will resolve to STUDIO\Domain Users
path_log=".dmc_adduser"

# Verify user is running with admin privileges
if [ ! "$(id -u)" -eq 0 ]
then
    >&2 echo "This must be run as sudo or root"
    exit 1
fi

# Verify users were provided as arguments
if [ $# -lt 1 ]
then
    echo "No users were provided"
    exit 1
fi

echo -e "\n$(date) =======" >> $path_log
echo "Command used: $0 $@" >> $path_log
echo "Creating accounts for $# user(s)..."

# Loop per-user
for username in "$@"
do
    # Check if user is valid, using id
    userinfo=$(id $username > /dev/null 2>&1)
    userexists=$?
    if [ $userexists -ne 0 ]
    then
        echo "Unknown user: $username.  Skipping." > /dev/stderr
        echo -e "[$username]\tUnknown user: $userinfo" >> $path_log
        continue
    fi

    # Query home folder using ~user
    userfolder=$(eval echo ~$username)
    echo -e "[$username]\tUsing folder $userfolder" >> $path_log

    # Check if already exists
    if [ -d $userfolder ]
    then
        echo -e "[$username]\tUser folder already exists" >> $path_log
        echo "User folder for $username already exists at $userfolder.  Skipping."
        continue
    fi

    # Create it
    folder_result=$(mkdir $userfolder)
    folder_success=$?

    if [ $folder_success -ne 0 ]
    then
        echo "Could not create a folder for $username: $folder_result"
        echo -e "[$username]\tError creating folder: $folder_result" >> $path_log
        continue
    elif [ ! -d $userfolder ]
    then
        echo "Could not create a folder for $username for unknown reasons."
        echo -e "[$username]\tUnknown error creating folder" >> $path_log
        continue
    else
        echo "Folder created successfully for $username at $userfolder"
        echo -e "[$username]\tFolder created successfully at $userfolder" >> $path_log
    fi

    # Adjust owner
    owner_result=$(chown -R $username $userfolder)
    owner_success=$?

    if [ $owner_success -ne 0 ]
    then
        echo "Error setting $username as the owner: $owner_result"
        echo -e "[$username]\tError setting $username as owner: $owner_result" >> $path_log
    else
        echo -e "[$username]\tOwner changed to $username for $userfolder" >> $path_log
    fi
    
    # Adjust group
    group_result=$(chgrp -R "$group_name" $userfolder)
    group_success=$?

    if [ $group_success -ne 0 ]
    then
        echo "Error setting STUDIO\\$group_name as the group: $group_result"
        echo -e "[$username]\tError setting STUDIO\\$group_name as group: $group_result" >> $path_log
    else
        echo -e "[$username]\tGroup changed to STUDIO\\$group_name for $userfolder" >> $path_log
    fi
    
    if [ $owner_success -ne 0 ] || [ $group_success -ne 0 ]
    then
        echo "Had trouble adjusting the permissions for $userfolder"
    fi

    # TODO: Perform checks using stat -f "%Su" folder   and   stat -f "%Sg" folder?
done