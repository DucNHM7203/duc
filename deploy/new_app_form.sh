#!/bin/bash

# Save current directory and cd into script path
initial_working_directory=$(pwd)
my_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

# Load common
source $my_path/../common/helpers.sh

# Get user name
read -p "Enter the deployment username (e.g., demo_1):" username

# Check if the user exists
while [ -z "$username" ] || [ $(getent passwd "$username") ]; do
  echo "The username '$username' already exists."
  read -p "Enter another deployment username:" username
done

# Enter deployment user password
read -s -p "Deployment user password: " password
echo

# Confirm the password
read -s -p "Confirm deployment user password: " confirm_password
echo
if [[ "$password" != "$confirm_password" ]]; then
  echo "Passwords do not match."
  exit 1
fi

# Enter the deployment user MySQL password
read -s -p "Deployment user MySQL password: " mysql_password
echo

# Confirm the MySQL password
read -s -p "Confirm deployment user MySQL password: " confirm_mysql_password
echo
if [[ "$mysql_password" != "$confirm_mysql_password" ]]; then
  echo "Passwords do not match."
  exit 1
fi

# Enter the application port number
read -p "Application port number (e.g., 8000): " application_port
echo

# Enter the git repo url
read -p "Git repo url: " git_repo_url
echo

php_version="8.3"

# Prompt the user if the app is Laravel application
read -p "Is this a Laravel app?  (y or Y for Yes): " yes_or_no
echo

# Check if the input is valid
is_laravel=false
if [[ $yes_or_no == "y" ]] || [[ $yes_or_no == "Y" ]]; then
  is_laravel=true
fi

# Public SSH Key for Remote Access As Deployment User
read -p "Public SSH Key for Remote Access As Deployment User: " public_ssh_key
echo

cp $my_path/_app.sh $my_path/../apps/$username.sh
sed -i "s|username=UNAME|username=$username|" $my_path/../apps/$username.sh
sed -i "s|password=PWORD|password=$password|" $my_path/../apps/$username.sh
sed -i "s|db_password=DB_PWORD|db_password=$mysql_password|" $my_path/../apps/$username.sh
sed -i "s|app_port=PORT|app_port=$port|" $my_path/../apps/$username.sh
sed -i "s|repo=REPO_URL|repo=$repo|" $my_path/../apps/$username.sh
sed -i "s|php_version=PHP_VERSION|php_version=$php_version|" $my_path/../apps/$username.sh
sed -i "s|is_laravel=IS_LARAVEL|is_laravel=$is_laravel|" $my_path/../apps/$username.sh
sed -i "s|public_ssh_key=PUB_SSH_KEY|public_ssh_key=$public_ssh_key|" $my_path/../apps/$username.sh


# Return back to the original directory
cd $initial_working_directory || exit
