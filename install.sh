#!/bin/bash

# Check to see if Homebrew is installed, and install it if it is not
#command -v brew >/dev/null 2>&1 || { \
#echo >&2 "Installing Homebrew Now"; \
#/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"; \
#}

echo 'Checking if Homebrew is installed'
which -s brew
if [[ $? != 0 ]] ; then
    echo 'Installing Homebrew'
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
    echo 'Updating Homebrew'
    brew update
fi


## Toolchain

# *I think the homebrew install script shoudl take care of this*
#echo 'Installing xcode commandline tools'
#xcode-select --install > /dev/null 2>&1

echo 'Installing Git if not available'
which -s git || brew install git

echo 'Checking if PHP 7.1 is installed'
if ! brew ls --versions php@7.1 > /dev/null; then
  echo "Installing PHP 7.1"
  brew install php@7.1
fi

## Composer
echo 'Installing Composer if not available'
which -s composer || brew install composer

# Finally install Valet+
if ! composer global show weprovide/valet-plus > /dev/null 2>&1; then
  echo 'Installing Valet+'
  composer global require weprovide/valet-plus
fi

echo 'Adding composer to shell PATH'
[[ ":$PATH:" != *":$HOME/.composer/vendor/bin:"* ]] && PATH="${PATH}:$HOME/.composer/vendor/bin"

echo 'Running Valet+ pre-launch checks'
valet fix
echo 'Running Valet+'
echo "- - There's going to be a lot of output... Remember to 'Allow' any firewall warnings"
valet install --with-mariadb

echo 'Creating ~/Sites to serve from'
mkdir ~/Sites && cd ~/Sites && valet park > /dev/null 2>&1

echo 'Emails can be seen at http://mailhog.test/'
echo 'Any folder created in ~/Sites/ will be avilable at http://folder_name.test'
echo 'In a folder run:'
echo 'wp core download --locale=en_GB && wp config create --dbname=${PWD##*/} --dbuser=root --dbpass=root && wp db create --dbuser=root --dbpass=root && wp core install --url=${PWD##*/}.test --title=${PWD##*/} --admin_user=admin --admin_password=admin --admin_email=admin@${PWD##*/}.test'
echo 'Then:'
 # mkdir grantham && cd grantham
 #
 # FULL SYNC
 # ssh petunia "cd /var/www/grantham2017.helpful.ws && wp search-replace 'grantham2017.helpful.ws' 'grantham.test' --all-tables --export "" | wp db import -
 # rsync -avz petunia:/var/www/grantham2017.helpful.ws/wp-content ./
 #
 # IF NOT SYNCING UPLOADS
 # # ssh petunia "cd /var/www/grantham2017.helpful.ws && wp search-replace 'grantham2017\.helpful\.ws(?:\/wp-content\/uploads)' 'grantham\.test' --regex --all-tables --export " | wp db import -
 # # rsync -avz petunia:/var/www/grantham2017.helpful.ws/wp-content/themes ./wp-content/ && rsync -avz petunia:/var/www/grantham2017.helpful.ws/wp-content/plugins ./wp-content/
 # valet secure
 # try_prod='location ~* \.(png|jpe?g|gif|ico)$ {expires 24h;log_not_found off;try_files $uri $uri/ @production;}location @production {resolver 8.8.8.8;proxy_pass http://grantham2017.helpful.ws/$uri;}'; sed -i -e "s#error_page#${try_prod}error_page#" ~/.valet/Nginx/grantham.test
 #

