#!/bin/bash

# Save current directory and cd into script path
initial_working_directory=$(pwd)
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"

# Load the helpers
source $parent_path/../helpers.sh

# Load the config file
source $parent_path/../config.sh

# Guard against overwriting and existing user
if id "$username" >/dev/null 2>&1; then
  error "This user already exists. Username: $username"
else
  # Create the deployment user
  title "Create Deployment User: $username"
  sudo adduser --gecos "" --disabled-password $username
  sudo chpasswd <<<"$username:$password"

  # Start a new session with this new user
  title "Creating Github Deployment Keys"
  sudo su - $username <<EOF
# Create the Github keys
ssh-keygen -f ~/.ssh/github_rsa -t rsa -N ""
cat <<EOT >> ~/.ssh/config
Host github.com
        IdentityFile ~/.ssh/github_rsa
        IdentitiesOnly yes
EOT
chmod 700 ~/.ssh
chmod 600 ~/.ssh/*

error "----------------------COPY PUB KEY TO GITHUB DEPLOYMENT KEYS---------------------"
cat < ~/.ssh/github_rsa.pub
error "---------------------------------------------------------------------------------"

# End session
exit
EOF

  sudo usermod -a -G $username www-data
fi

title "Creating Initial Deployment"
sudo -u $username $parent_path/deploy.sh

exit 0

# Create the initial deployment
deploy_directory=/home/$username/deployments
folder_name="initial"

# Only needed to delete this directory
sudo chown $username:$username -R /home/$username/deployments/releases

sudo su - $username <<INIT
if [ ! -d $deploy_directory ]; then
  mkdir -p $deploy_directory
fi
if [ ! -d $deploy_directory/releases ]; then
  mkdir -p $deploy_directory/releases
fi
cd $deploy_directory/releases
if [ -d $folder_name ]; then
  rm -rf $folder_name
fi
git clone --depth 1 $repo $folder_name

# Create the initial symlinked repository
if [ ! -d $deploy_directory/symlinks ]; then
  mkdir -p $deploy_directory/symlinks
fi
if [ "$is_laravel" = true ]; then

  if [ ! -f $deploy_directory/symlinks/.env ]; then
    cp .env $deploy_directory/symlinks/.env
  fi
  if [ ! -d $deploy_directory/symlinks/public ]; then
   mkdir -p $deploy_directory/symlinks/public
  fi
  if [ ! -d $deploy_directory/symlinks/public/cache ]; then
   cp -r public/cache $deploy_directory/symlinks/public/cache
  fi
  if [ ! -d $deploy_directory/symlinks/public/data ]; then
   cp -r public/data $deploy_directory/symlinks/public/data
  fi
  if [ ! -d $deploy_directory/symlinks/storage ]; then
    cp -r storage $deploy_directory/symlinks/storage
  fi
  if [ ! -f $deploy_directory/symlinks/database.sqlite ]; then
    cp -r database/database.sqlite $deploy_directory/symlinks/database.sqlite
  fi
fi

cd $deploy_directory/releases/$folder_name

# Activate this releases
source $parent_path/create_symlinks.sh

# Build the application
echo "Building the application"
source $parent_path/build.sh

# Activate this new version
echo "Activate the new version"
source $parent_path/activate.sh

# Cron configuration
#(crontab -l 2>/dev/null; echo "* * * * * cd $deploy_directory/current/ && php artisan schedule:run >> $deploy_directory/current/storage/logs/cron.log 2>&1") | crontab -

INIT

# Create nginx conf
if [ ! -f /etc/nginx/sites-available/$username.conf ]; then
    sudo cp $parent_path/laravel.conf /etc/nginx/sites-available/$username.conf
    sudo sed -i "s|root;|root $deploy_directory/current/public;|" /etc/nginx/sites-available/$username.conf
    sudo sed -i "s|phpXXXX|php$php_version|" /etc/nginx/sites-available/$username.conf
    sudo ln -s /etc/nginx/sites-available/$username.conf /etc/nginx/sites-enabled/$username.conf
    sudo service nginx reload
fi
if [ ! -f /etc/php/$php_version/fpm/pool.d/$username.conf ]; then
    sudo cp /etc/php/$php_version/fpm/pool.d/www.conf /etc/php/$php_version/fpm/pool.d/$username.conf
    sudo sed -i "s|\[www\]|[$username]|" /etc/php/$php_version/fpm/pool.d/$username.conf
    sudo sed -i "s/user =.*/user = $username/" /etc/php/$php_version/fpm/pool.d/$username.conf
    sudo sed -i "s/group =.*/group = $username/" /etc/php/$php_version/fpm/pool.d/$username.conf
    sudo sed -i "s/listen\.owner.*/listen.owner = $username/" /etc/php/$php_version/fpm/pool.d/$username.conf
    sudo sed -i "s/listen\.group.*/listen.group = $username/" /etc/php/$php_version/fpm/pool.d/$username.conf
    sudo sed -i "s|listen =.*|listen = /run/php/php$php_version-$username-fpm.sock|" /etc/php/$php_version/fpm/pool.d/$username.conf
    sudo service php$php_version-fpm restart
fi

# Create supervisor conf
if [ ! -f /etc/supervisor/conf.d/$username.conf ]; then
    sudo cp $parent_path/horizon.conf /etc/supervisor/conf.d/$username.conf
    sudo sed -i "s|program:|program:horizon_$username|" /etc/supervisor/conf.d/$username.conf
    sudo sed -i "s|command=|command=php $deploy_directory/current/artisan horizon|" /etc/supervisor/conf.d/$username.conf
    sudo sed -i "s|user=|user=$username|" /etc/supervisor/conf.d/$username.conf
    sudo sed -i "s|stdout_logfile=|stdout_logfile=$deploy_directory/current/storage/logs/horizon.log|" /etc/supervisor/conf.d/$username.conf
    sudo supervisorctl reread
    sudo supervisorctl update
fi

# Return back to the original directory
cd $initial_working_directory || exit
