#!/bin/bash

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

read -p "[-] enter remote site folder name, e.g. helpfultechnology.com : " remote_site

read -p "[-] enter new local site folder name (no tld, it will be xxx.test), e.g. helpfultechnology : " local_site
local_site_path="${HOME}/Sites/${local_site}"

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
echo -e '\r[-' ; echo

cd $local_site_path

echo -n "[ ] deploying WordPress..."
wp core download --locale=en_GB > /dev/null 2>&1 && wp config create --dbname=${PWD##*/} --dbuser=root --dbpass=root > /dev/null 2>&1 && wp db create --dbuser=root --dbpass=root > /dev/null 2>&1 && wp core install --url=${PWD##*/}.test --title=${PWD##*/} --admin_user=admin --admin_password=admin --admin_email=admin@${PWD##*/}.test
echo -e '\r[-' ; echo

echo -n "[ ] pulling down data... (be patient)"
# Pull db and search-replace inline.
ssh ${remote_server} "cd /var/www/${remote_site} && wp search-replace '${remote_site_url}' 'http://${local_site}.test' --all-tables --export --skip-plugins --skip-themes 2> /dev/null" | wp db import --skip-plugins --skip-themes - > /dev/null 2>&1
# Deactivate problematic plugins.
wp plugin deactivate wp-super-cache 2&> /dev/null && wp plugin deactivate w3-total-cache 2&> /dev/null && wp plugin deactivate autoptimize 2&> /dev/null && wp plugin deactivate cloudflare 2&> /dev/null && wp plugin deactivate google-captcha 2&> /dev/null
# Pull wp-content.
rsync -avz ${remote_server}:/var/www/${remote_site}/wp-content ./ > /dev/null 2>&1
# Create temp admin user
wp user create admin admin@${local_site}.test --role=administrator --user_pass=admin > /dev/null 2>&1
echo -e '\r[-' ; echo

echo -e "\n[${GREEN}\xE2\x9C\x94${NC}] ${GREEN}Done - you can now access ${admin_site}.test in your browser.\nA new user 'admin' with password 'admin' has been created.\nOpening in your default browser now...${NC}"
sleep 5 ; valet open

# NginX block to get missing media from remote.
# https://medium.com/@connor_78150/hey-devron-baldwin-4a145add21f2
