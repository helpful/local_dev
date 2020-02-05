#!/usr/local/bin/bash
# Setup HD local dev based on Laravel Valet+
# v1.2.1


bold=$(tput bold)
normal=$(tput sgr0)


## Safety first.

echo # Spacer.
echo "[install.sh] You are about to deploy a Mac local development environment."
echo "[install.sh] There are no prompts after this and very little error handling, so pay attention to the output."
read -p "[install.sh] ${bold}Are you sure you want to install?${normal} (y to continue) " -n 1 -r
echo # Spacer.
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo "[install.sh] ${bold}Aborted by user. Bye.${normal}."
    echo # Spacer.
    exit 1
fi
echo "[install.sh] There's going to be a lot of output from here... You may be prompted for your password, and to 'Allow' a firewall warning."
echo # Spacer.


## Prerequisites.

echo "[install.sh] Installing Homebrew if not available."
which -s brew
if [[ $? != 0 ]] ; then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
    echo "[install.sh] Updating Homebrew."
    brew update
fi

echo "[install.sh] Installing Git if not available."
which -s git || brew install git

echo "[install.sh] Adding brew tap for Valet+ PHP versions."
brew tap henkrehorst/php

echo "[install.sh] Installing Valet+ version of PHP7.2 if not available."
if ! brew ls --versions valet-php@7.2  > /dev/null; then
  echo "Installing Valet+ version of PHP7.2."
  brew install valet-php@7.2
fi

echo "[install.sh] Installing Composer if not available."
which -s composer || brew install composer

echo "[install.sh] Adding Composer to shell PATH."
[[ ":$PATH:" != *":$HOME/.composer/vendor/bin:"* ]] && PATH="${PATH}:$HOME/.composer/vendor/bin"


## Main event.

# Deploy Valet+.
if ! composer global show weprovide/valet-plus > /dev/null 2>&1; then
  echo "[install.sh] Deploying Valet+."
  composer global require weprovide/valet-plus
fi

echo "[install.sh] Running Valet+ pre-launch checks."
valet fix
echo "[install.sh] Running Valet+ install."
valet install --with-mariadb

# Setup Valet+ sites.
echo "[install.sh] Creating ~/Sites to serve from."
sites_dir="${HOME}/Sites"
if [[ -d "${sites_dir}" ]] ; then
  echo "[install.sh] ${bold}~/Sites already exists but is presumed available. I am cautious so you will need to manually run 'valet park' in that folder if you are happy to use it. If not, run it in another directory, but you will have to modify clone.sh to match.${normal}"
else
  mkdir ${HOME}/Sites && cd ${HOME}/Sites && valet park > /dev/null 2>&1
fi


## Happy days.

echo "Emails will be caught and can be seen at http://mailhog.test/."
echo "Any folder created in ~/Sites/ will be avilable at http://folder_name.test, but wouldn't it be easier if..."
# Icing on the cake - install clone.sh.
curl -o /usr/local/bin/clone.sh -fsSL https://raw.githubusercontent.com/helpful/local_dev/master/clone.sh ; chmod +x /usr/local/bin/clone.sh
echo "[install.sh] Installing clone.sh WP helper."
echo "Now just run clone.sh to automate the cloning of a remote WP site to your machine."
