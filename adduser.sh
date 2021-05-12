#!/bin/bash

path_exec='/System/Library/CoreServices/ManagedClient.app/Contents/Resources/createmobileaccount'
path_log=".dmc_adduser"


# Verify user is running with admin privileges
if [ ! "$(id -u)" -eq 0 ]
then
    >&2 echo "This must be run as sudo or root"
    exit 1
fi

# Verify `createmobileaccount` is a valid executable
if [ ! -e $path_exec ]
then
    >&2 echo "System executable does not exist:"
    echo $path_exec
    exit 1
elif [ ! -x $path_exec ]
then
    >&2 echo "System executable is not executable:"
    echo $path_exec
    exit 1
fi

if [ $# -lt 1 ]
then
    echo "No users were provided"
    exit 1
fi

echo -e "\n$(date) =======" >> $path_log
echo "Command used: $0 $@" >> $path_log

echo -e "\nCreating accounts for $# user(s)...\n"

for username in "$@"
do
    # Skip existing
    id $username > /dev/null 2>&1
    if [ $? -eq 0 ]
    then
        userfolder=$(eval echo ~$1)
        echo -e "[$username]\tHome folder already exists at $userfolder" >> $path_log
        echo "Skipping $username: Home folder already exists at $userfolder"
        continue
    fi

    
    # Try to actually add the user
    echo "Adding user home folder for $username"
    command_adduser="$path_exec -D -n $username"
    echo -e "[$username]\tRunning command: $command_adduser" >> $path_log

    # Add mobile user
    command_output=$($command_adduser)
    command_code=$?

    # Check user created
    # TODO: Add these checks
    id $username > /dev/null 2>&1
    user_created=$?

    # Check output
    if [ $command_code -ne 0 ]
    then
        echo -e "[$username]\tError: $command_code" >> $path_log
        echo "$command_output" | sed 's/^/  /' >> $path_log
        echo "Could not add $username: $command_output"
    else
        echo -e "[$username]\tSuccessfully added user" >> $path_log
        echo -e "[$username]\tDirectory created: $(eval echo ~$username)" >> $path_log
        echo -e "[$username]\tAdditional output:" >> $path_log
        echo "$command_output" | sed 's/^/  /' >> $path_log
    fi

    #echo ""

done