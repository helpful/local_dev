#!/usr/bin/env bash
# Tear down HD local dev redy for re-install of Laravel Valet+ v2x
# Leave database system in place
# Tested against Mac OS 10.15 (Catalina)
# v1.0.0


bold=$(tput bold)
normal=$(tput sgr0)


## Safety first.

echo # Spacer.
echo "[uninstall.sh] You are about to uninstall your Mac local development environment."
echo "[uninstall.sh] There are no prompts after this and very little error handling, so pay attention to the output."
echo "[uninstall.sh] This may also affect other systems on your machine if they use the same packages."
read -p "[uninstall.sh] ${bold}Are you sure you want to uninstall?${normal} (y to continue) " -n 1 -r
echo # Spacer.
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "[uninstall.sh] ${bold}Aborted by user. Bye.${normal}."
    echo # Spacer.
    exit 1
fi


# Handle nuke argument for more thorough clean up.
if [ $# -ge 1 ]
then
    if [ "$1" != "nuke" ]; then
        echo 'Either run this script with no arguments to do a re-install prep, or "nuke" to do a more thorough clean up **that will also delete the databases**.' ; exit 1
    else
      read -p "[uninstall.sh] ${bold}You've chosen to delete everything, including databases and the ~/Sites directory. Are you sure you want to continue?${normal} (y to continue) " -n 1 -r
      if [[ ! $REPLY =~ ^[Yy]$ ]]
      then
          echo "[uninstall.sh] ${bold}Aborted by user. Bye.${normal}."
          echo # Spacer.
          exit 1
      fi
    fi
else
  echo "[uninstall.sh] There's going to be a lot of output from here... It is expected that some commands fail, and you may be prompted for your password."
fi

echo # Spacer.

valet stop
sudo valet stop

composer global remove laravel/valet
composer global remove weprovide/valet-plus

brew services stop --all
brew uninstall dnsmasq
brew uninstall nginx
brew uninstall php
brew uninstall valet-php@7.1
brew uninstall valet-php@7.2
brew uninstall mailhog
brew uninstall redis

if [ $# -ge 1 ]
then
    if [ "$1" == "nuke" ]; then
        brew uninstall mysql
        brew uninstall mariadb
        sudo rm -rf ~/Sites
    fi
fi

brew cleanup
brew prune
brew doctor

sudo rm -rf ~/.valet
sudo rm -rf ~/.composer/vendor/weprovide/
sudo rm -rf /usr/local/etc/valet-php

## Happy days.

echo "[uninstall.sh] Done. You can now re-run the installer if you are trying to fix a config problem."
