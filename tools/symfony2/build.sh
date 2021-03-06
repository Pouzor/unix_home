#!/bin/bash

#########################################
###       Bash script location        ###
#########################################

realpath() {
  OURPWD=$PWD
  cd "$(dirname "$1")"
  LINK=$(readlink "$(basename "$1")")
  while [ "$LINK" ]; do
    cd "$(dirname "$LINK")"
    LINK=$(readlink "$(basename "$1")")
  done
  REALPATH="$PWD/$(basename "$1")"
  cd "$OURPWD"
  echo "$REALPATH"
}

# current script command line call
#Work for GNU Linux and BSD and MacOSX
scriptCall="$(realpath "${BASH_SOURCE[0]}")"
# only work on GNU Linux
#scriptCall="$(readlink -f ${BASH_SOURCE[0]})"
# directory of the script
scriptDir=$(dirname "$scriptCall")
# script base name
scriptName=$(basename "$scriptCall")

#########################################
###        OS basic detection         ###
#########################################

case "$OSTYPE" in
  linux*)   
    currentOS="linux";;
  darwin*)
    currentOS="macosx";;
  solaris*)
    currentOS="solaris";;
  cygwin)
    currentOS="windows";;
  win*)
    currentOS="windows";;
  freebsd*)
    currentOS="bsd";;
  bsd*)
    currentOS="bsd";;
  *)
    currentOS="unknown";;
esac

#########################################
###  default variable configuration   ###
#########################################

phpbin=php
curlbin=curl

assetOptions='--symlink --relative'
#assetOptions=''

#########################################
###  import variable configuration    ###
#########################################

CONFIG_FILE=../build.conf
CONFIG_FILE_DIST=$CONFIG_FILE.dist

if [[ -f $CONFIG_FILE ]]; then
    . $CONFIG_FILE
elif [[ -f $CONFIG_FILE_DIST ]]; then
    . $CONFIG_FILE_DIST
fi

########################################
###          Main program            ###
########################################

#install vendors
bash composer.sh

# clear cache
$phpbin app/console cache:clear --env=dev
$phpbin app/console cache:clear --env=prod

# install assets
$phpbin app/console assets:install $assetOptions web 

$phpbin app/console assetic:dump --env=dev
$phpbin app/console assetic:dump --env=prod --no-debug

# build model and check for database migration
$phpbin app/console propel:build
rm app/propel/migrations/PropelMigration*
$phpbin app/console propel:migration:generate-diff
$phpbin app/console propel:migration:status

read -p "migrate database (y/n) ? " -n 1 migrate
echo ""
if [ "$migrate" == "y" -o "$migrate" == "Y" ]; then
    $phpbin app/console propel:migration:migrate 
fi
