#!/bin/bash

function title {
    echo "-------------------------------------"
    echo ""
    echo "$1"
    echo ""
    echo "-------------------------------------"
}

# Save current directory and cd into script path
initial_working_directory=$(pwd)
parent_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
cd "$parent_path"

# Load the config file
source ../config.sh


# create a directory for git clone
foldername=$(date +%Y%m%d%H%M%S)

{
    sudo su vagrant

    # create the directory structure
    title "Deploying: $foldername"
    if [ ! -d $deploy_directory/releases ]; then
        sudo mkdir -p $deploy_directory/releases
        sudo chown -R $username:$username $deploy_directory/releases
    fi
    cd $deploy_directory/releases
    echo  "folder=$deploy_directory/releases/$foldername"

    # git clone into this new directory
    git clone --depth 1 $repo $foldername

    # composer install
    title "Dependencies"
    cd $foldername
    /usr/bin/composer install
    /usr/bin/npm install

    # create symlinks
    title Activation
    source /srv/code/web/scripts/activate.sh $foldername

    # migrations
    title Migrations
    source artisan migrate --force

    # restart services
    source /srv/code/web/scripts/restart.sh

    # cleanup
    source /srv/code/web/scripts/clean_up.sh

    exit
} 2>&1

# Return back to the original directory
cd $initial_working_directory
