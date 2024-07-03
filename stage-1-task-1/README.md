# Overview

The create_users.sh script is designed to create users on a Linux system based on information provided in a specified file. It generates random passwords for the users, assigns them to groups, logs all actions performed, and stores usernames and passwords in a secure CSV file. The script also ensures that any required directories and files exist and have appropriate permissions.

## Script Breakdown

#### Shebang and Argument Check

```bash
#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Usage: $0 <filename>"
  exit 1
fi
```

Purpose: Specifies the script interpreter (Bash) and ensures exactly one argument (filename) is provided.

#### Filename Assignment and File Check

```bash
filename="$1"

if [ ! -f "$filename" ]; then
  echo "File $filename not found!"
  exit 1
fi
```

Purpose: Assigns the input filename and checks if the file exists.

#### Define Paths and Ensure Directories/Files Exist

```bash
logfile="/var/log/user_management.log"
passwordfile="/var/secure/user_passwords.csv"

sudo mkdir -p /var/log
sudo mkdir -p /var/secure

sudo touch "$logfile"
sudo touch "$passwordfile"

sudo chmod 640 "$logfile"
sudo chmod 600 "$passwordfile"
```

Purpose: Sets paths for log and password files, ensures directories and files exist, and sets appropriate permissions.

#### Log script start

```bash
{
  echo -e "\n==============================="
  echo "Script started on $(date)"
  echo "==============================="
} | sudo tee -a "$logfile"
```

```bash
{
  echo "==============================="
  echo "Script ended on $(date)"
  echo "==============================="
} | sudo tee -a "$logfile"
```

Purpose: Logs the start and end of the script with a timestamp and demarcation.

#### Password generation function

```bash
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
```

#### Write CSV Header if File is Empty

```bash
if [ ! -s "$passwordfile" ]; then
  echo "username,password" | sudo tee "$passwordfile" > /dev/null
fi
```

Purpose: Ensures the CSV file has a header if it's empty.

#### Process input file

```bash
while IFS= read -r line
do
  username=$(echo "$line" | cut -d';' -f1 | xargs)
  groups=$(echo "$line" | cut -d';' -f2 | tr ',' ' ' | xargs)

  if [[ "$username" =~ [^a-zA-Z0-9._-] ]]; then
    echo "Error: Username $username contains special characters. Skipping user creation." | sudo tee -a "$logfile"
    continue
  fi

  if id "$username" &>/dev/null; then
    echo "User $username already exists." | sudo tee -a "$logfile"
  else
    password=$(generate_password)
    sudo useradd -m -s /bin/bash -p "$(perl -e 'print crypt($ARGV[0], "password")' "$password")" "$username"
    if [ $? -eq 0 ]; then
      echo "User $username has been added to the system." | sudo tee -a "$logfile"
      echo "$username,$password" | sudo tee -a "$passwordfile" > /dev/null
      for group in $groups; do
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
```

Purpose: Reads each line, extracts username and groups, checks for special characters, and creates the user if valid. Assigns groups and logs actions.

## Summary

The `create_users.sh` script automates user creation, group assignments, password generation, and logging, ensuring security and traceability. It processes an input file, handles errors, and maintains organized logs and password records.

#### Credits

This project was done courtesy via the [HNG 11 Internship program](https://hng.tech/internship). You can find and hire quality interns on [https://hng.tech/hire](https://hng.tech/hire).
