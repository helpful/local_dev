#!/bin/bash
#
# clone.sh
# Pull a remote WordPress site to a Laravel Valet based local staging site.
#

# Colours.
NC='\x1B[0m' # no colour
RED='\x1B[0;31m'
GREEN='\x1B[0;32m'
YELLOW='\x1B[0;33m'

# Read required vars.
read -p "[-] enter remote server name, e.g. petunia : " remote_server
ping -c 1 ${remote_server} &>/dev/null \
  || { ping -c 1 ${remote_server}.helpful.im &>/dev/null && remote_server=${remote_server}.helpful.im ; } \
  || { echo -e "\n[${RED}x${NC}] ${RED}Host '${remote_server}' does not ping, exiting...${NC}\n" ; exit 1 ; }

possible_sites=($(ssh ${remote_server} 'cd /var/www/ ; find ./* -depth -maxdepth 4 -path "*wp-includes/version.php" | sed -e "s#\./\(.*\)/wp-includes/version.php#\1#" '))
PS3="[-] choose remote site : "
select chosen_site in "${possible_sites[@]}" ; do remote_site=${chosen_site} ; break; done ;
echo "[-] selected ${remote_site}" ;

read -p "[-] enter new local site folder name (no tld, it will be xxx.test), e.g. helpful : " local_site
local_site_path="${HOME}/Sites/${local_site}"


# Add identity to agent otherwise this will get really annoying...
echo -n "[-] " ; ssh-add


# Spacer.
echo


# Get remote site url as test everything's ok.
remote_site_url=$(ssh ${remote_server} "cd /var/www/${remote_site} 2> /dev/null && wp option get siteurl --skip-plugins --skip-themes 2> /dev/null") ;
if [ -z "${remote_site_url}" ]; then
  echo -e "\n[${RED}x${NC}] ${RED}Couldn't not retrive siteurl from remote. Check server and site/folder name and try again, exiting...${NC}\n" ; exit 1 ;
fi


# Create host directory.
if [ -d "${local_site_path}" ]; then
  echo -e "\n[${RED}x${NC}] ${RED}Folder '${local_site_path}' already exists, exiting...${NC}\n" ; exit 1 ;
fi
echo -n "[ ] creating ${local_site_path}"
mkdir $local_site_path
echo -e "\r[${GREEN}\xE2\x9C\x94${NC}"

# Move to host directory.
cd $local_site_path


# Setup clean local WP install.
echo -n "[ ] deploying WordPress..."
wp core download --locale=en_GB > /dev/null 2>&1 && wp config create --dbname=${PWD##*/} --dbuser=root --dbpass=root > /dev/null 2>&1 && wp db create --dbuser=root --dbpass=root > /dev/null 2>&1 && wp core install --url=${PWD##*/}.test --title=${PWD##*/} --admin_user=admin --admin_password=admin --admin_email=admin@${PWD##*/}.test > /dev/null 2>&1
echo -e "\r[${GREEN}\xE2\x9C\x94${NC}"


# Pull the live data in.
echo -n "[ ] pulling down data... (be patient)"
# Pull wp-content.
rsync -az ${remote_server}:/var/www/${remote_site}/wp-content ./ > /dev/null 2>&1

# Pull db and search-replace inline.
ssh ${remote_server} "cd /var/www/${remote_site} && wp search-replace '${remote_site_url}' 'http://${local_site}.test' --all-tables --export --skip-plugins --skip-themes 2> /dev/null" | wp db import --skip-plugins --skip-themes - > /dev/null 2>&1
# Update database prefix, in case not wp_.
remote_site_prefix=$(ssh ${remote_server} "cd /var/www/${remote_site} 2> /dev/null && wp config get table_prefix 2> /dev/null") ;
wp config set table_prefix ${remote_site_prefix} > /dev/null 2>&1

# Deactivate problematic plugins.
wp plugin deactivate wppusher 2&> /dev/null && wp plugin deactivate wp-super-cache 2&> /dev/null && wp plugin deactivate w3-total-cache 2&> /dev/null && wp plugin deactivate autoptimize 2&> /dev/null && wp plugin deactivate cloudflare 2&> /dev/null && wp plugin deactivate google-captcha 2&> /dev/null && wp plugin deactivate better-wp-security 2&> /dev/null

# Create temp admin user
wp user create admin admin@${local_site}.test --role=administrator --user_pass=admin > /dev/null 2>&1
echo -e "\r[${GREEN}\xE2\x9C\x94${NC}"


# We are done.
echo -e "\n[${GREEN}\xE2\x9C\x94${NC}] ${GREEN}Done - you can now access ${admin_site}.test in your browser.\nA new user 'admin' with password 'admin' has been created.\nOpening in your default browser now...${NC}"
sleep 5 ; valet open

# NginX block to get missing media from remote.
# https://medium.com/@connor_78150/hey-devron-baldwin-4a145add21f2

# Notes:
# - https://github.com/weprovide/valet-plus
# - see emails at http://mailhog.test
# - if you get front not returned error, try:
# - - cd into site directory (~/Sites/xxx)
# - - valet link && valet config
# - - now try in browser
# - if you are seeing php errors on the screen
# - - ini_set('display_errors','Off');
# - - ini_set('error_reporting', E_ALL );
# - - define('WP_DEBUG', false);
# - - define('WP_DEBUG_DISPLAY', false);
# - php ini file used is /usr/local/etc/php/7.1/php.ini
# - Logs are in ~/.valet/Log/

# Useful commands:
# - valet open
# - valet db open <name> (will guess if no name specified, dbname defaults to folder name)
# - valet restart
# - valet secure xxx (turn on https for the site in folder xxx)
# - valet share (puts url in clipboard for public access to site as long as process running; ctrl+c to stop)
# - valet db import <filename>.sql(.gz) <name> (guesses db name from git settings or folder name)
# - wp db import <filename> (uses db name from wp-config.php)
