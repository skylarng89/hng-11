#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <filename>"
  exit 1
fi

# Get the filename from the command-line argument
filename="$1"

# Check if the file exists
if [ ! -f "$filename" ]; then
  echo "File $filename not found!"
  exit 1
fi

# Define the log and password file paths
logfile="/var/log/user_management.log"
passwordfile="/var/secure/user_passwords.csv"

# Ensure the directories exist
sudo mkdir -p /var/log
sudo mkdir -p /var/secure

# Ensure the files exist
sudo touch "$logfile"
sudo touch "$passwordfile"

# Set permissions to the files to restrict access
sudo chmod 640 "$logfile"
sudo chmod 600 "$passwordfile"

# Log the start of the script with demarcation and line break
{
  echo -e "\n==============================="
  echo "Script started on $(date)"
  echo "==============================="
} | sudo tee -a "$logfile"

# Function to generate a random password
generate_password() {
  local charset='abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ23456789!@#$%^&*()_+=-'
  local password_length=12
  local password=""
  for i in $(seq 1 $password_length); do
    local rand_index=$(( RANDOM % ${#charset} ))
    local rand_char=${charset:$rand_index:1}
    password="$password$rand_char"
  done
  echo "$password"
}

# Write the CSV header if the file is empty
if [ ! -s "$passwordfile" ]; then
  echo "username,password" | sudo tee "$passwordfile" > /dev/null
fi

# Read the file line by line
while IFS= read -r line
do
  # Extract username and groups
  username=$(echo "$line" | cut -d';' -f1 | xargs)
  groups=$(echo "$line" | cut -d';' -f2 | tr ',' ' ' | xargs)
  
  # Check for special characters in the username
  if [[ "$username" =~ [^a-zA-Z0-9._-] ]]; then
    echo "Error: Username $username contains special characters. Skipping user creation." | sudo tee -a "$logfile"
    continue
  fi
  
  # Check if the user already exists
  if id "$username" &>/dev/null; then
    echo "User $username already exists." | sudo tee -a "$logfile"
  else
    # Generate a password
    password=$(generate_password)
    # Create the user with home directory and bash shell
    sudo useradd -m -s /bin/bash -p "$(perl -e 'print crypt($ARGV[0], "password")' "$password")" "$username"
    if [ $? -eq 0 ]; then
      echo "User $username has been added to the system." | sudo tee -a "$logfile"
      echo "$username,$password" | sudo tee -a "$passwordfile" > /dev/null
      # Process groups
      for group in $groups; do
        # Trim whitespace and check if the group exists
        group=$(echo "$group" | xargs)
        if ! getent group "$group" > /dev/null 2>&1; then
          sudo groupadd "$group"
          echo "Group $group created." | sudo tee -a "$logfile"
        fi
        sudo usermod -aG "$group" "$username"
        echo "User $username added to group $group." | sudo tee -a "$logfile"
      done
    else
      echo "Failed to add user $username." | sudo tee -a "$logfile"
    fi
  fi
done < "$filename"

# Log the end of the script with demarcation
{
  echo "==============================="
  echo "Script ended on $(date)"
  echo "==============================="
} | sudo tee -a "$logfile"
