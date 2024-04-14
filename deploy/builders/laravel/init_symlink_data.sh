#!/bin/bash

# Save current directory and cd into script path
my_path=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )

# Assumption: This is part of a deployment and is being run under the deployment user
app_name=$(whoami)

# Load common
source $my_path/../../../common/load_common.sh

symlink_directory=$deploy_directory/symlinks
echo "symlink_directory=$symlink_directory"

# Create the initial symlinked repository
if [ ! -d $symlink_directory ]; then
  mkdir -p $symlink_directory
fi
if [ "$app_type" = "laravel" ]; then

  if [ ! -f $symlink_directory/.env ]; then
    echo "Looking: .env"
    if [ -f .env ]; then
      cp .env $symlink_directory/.env
      echo "Copied: .env"
    else
      echo "Not Found: .env"
    fi
  else
    echo "Data exists: .env"
  fi

  if [ ! -d $symlink_directory/public ]; then
   mkdir -p $symlink_directory/public
  fi


  if [ ! -d $symlink_directory/public/cache ]; then
    echo "Looking: public/cache"
    if [ -d public/cache ]; then
      cp -r public/cache $symlink_directory/public/cache
      echo "Copied: public/cache"
    else
      echo "Not Found: public/cache"
    fi
  else
    echo "Data exists: public/cache"
  fi

  if [ ! -d $symlink_directory/public/data ]; then
    echo "Looking: public/data"
    if [ -d public/data ]; then
      cp -r public/data $symlink_directory/public/data
      echo "Copied: public/data"
    else
      echo "Not Found: public/data"
    fi
  else
    echo "Data exists: public/data"
  fi

  if [ ! -d $symlink_directory/storage ]; then
    echo "Looking: storage"
    if [ -d storage ]; then
      cp -r storage $symlink_directory/storage
      mkdir -p $symlink_directory/storage
      mkdir -p $symlink_directory/storage/backups
      mkdir -p $symlink_directory/storage/app
      mkdir -p $symlink_directory/storage/framework
      mkdir -p $symlink_directory/storage/framework/cache
      mkdir -p $symlink_directory/storage/framework/sessions
      mkdir -p $symlink_directory/storage/framework/views
      mkdir -p $symlink_directory/storage/logs
      echo "Copied: storage"
    else
      echo "Not Found: storage"
    fi
  else
    echo "Data exists: storage"
  fi

  if [ ! -f $symlink_directory/database.sqlite ]; then
    echo "Looking: database.sqlite"
    if [ -f database/databaser.sqlite ]; then
      cp -r database/database.sqlite $symlink_directory/database.sqlite
      echo "Copied: database.sqlite"
    else
      echo "Not Found: database.sqlite"
    fi
  else
    echo "Data exists: database.sqlite"
  fi
fi

# Activate the newly created symlink sources
title "Recreating Symlinks"
source $my_path/symlinks.sh