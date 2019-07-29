#!/bin/bash
#
# clone.sh
# Pull a remote WordPress site to a Laravel Valet based local staging site.
#

# Config vars.
DOMAIN='helpful.im' # Check this domain if entered server name doesn't ping on it's own.
VHOST_PATH='/var/www/' # Full path to the vhost dir - with trailing slash.
WPCONTENT_PATH='/wp-content' # Path to wp-content within a single vhost's dir - no trailing slash.
SITES_PATH="${HOME}/Sites/" # Local dir to store Valet sites - with trailing slash.

# Colours.
NC='\x1B[0m' # no colour
RED='\x1B[0;31m'
GREEN='\x1B[0;32m'
YELLOW='\x1B[0;33m'

# Gather required vars.
read -p "[ ] Enter remote server name, e.g. petunia : " remote_server
ping -c 1 ${remote_server} &>/dev/null \
  || { ping -c 1 ${remote_server}.${DOMAIN} &>/dev/null && remote_server=${remote_server}.${DOMAIN} ; } \
  || { printf "\033[1A\r[${RED}x${NC}" ; echo -e "\n[${RED}x${NC}] ${RED}Host '${remote_server}' does not ping, aborting...${NC}\n" ; exit 1 ; }
printf "\033[1A\r[${GREEN}\xE2\x9C\x94${NC}\n"

# Add identity to agent, if needed, otherwise this will get really annoying...
ssh-add -l &>/dev/null
if [[ $? -ne 0 ]] ; then
  echo -n "[-] " ;
  if ssh-add ; then
    printf "\033[1A\r\033[K[${GREEN}\xE2\x9C\x94${NC}] Identity added\n"
  else
    # Note: - not sure this will ever fire...
    echo -e "\n[${RED}x${NC}] ${RED}Failed to add ssh identity, aborting...${NC}\n" ; exit 1
  fi
else
  echo -e "[${GREEN}\xE2\x9C\x94${NC}] Identity added"
fi

possible_sites=($(ssh ${remote_server} 'cd '${VHOST_PATH}' ; find ./* -depth -maxdepth 4 -path "*wp-includes/version.php" | sed -e "s#\./\(.*\)/wp-includes/version.php#\1#" '))
PS3="[-] Choose remote site - enter the number from the list above, e.g. 1 : "
select chosen_site in "${possible_sites[@]}" ; do remote_site=${chosen_site} ; break; done ;
echo -e "[${GREEN}\xE2\x9C\x94${NC}] Selected: ${remote_site}" ;

read -p "[ ] Enter new local site folder name (no tld, it will be xxx.test), e.g. local-dev-site : " local_site
printf "\033[1A\r[${GREEN}\xE2\x9C\x94${NC}\n"
local_site_path="${SITES_PATH}${local_site}"


# Get remote site url as test that everything is ok.
remote_site_url=$(ssh ${remote_server} "cd ${VHOST_PATH}${remote_site}${WPCONTENT_PATH} 2> /dev/null && wp option get siteurl --skip-plugins --skip-themes 2> /dev/null") ;
if [[ -z "${remote_site_url}" ]] ; then
  echo -e "\n[${RED}x${NC}] ${RED}Could not retrive siteurl from remote. Check server and site/folder name and try again, aborting...${NC}\n" ; exit 1 ;
fi


# Create host directory.
if [[ -d "${local_site_path}" ]] ; then
  # Exists, prompt for action.
  dir_options=( 'abort' 'update all' 'update wp-content' 'update database' )
  PS3="[-] directory already exists - do you want to : "
  select dir_option in "${dir_options[@]}"
  do
  	case $dir_option in
  	  "abort")
        echo -e "\n[${RED}x${NC}] ${RED}Aborting...${NC}\n" ; exit 1
        break ;;
  	  "update all")
        update="all"
        break ;;
  	  "update wp-content")
        update="content"
        break ;;
  	  "update database")
        update="database"
        break ;;
  	  *)
        echo "Choose a valid option" ;;
    esac
  done
  echo -e "[${GREEN}\xE2\x9C\x94${NC}] Selected: update ${update}"
else
  # Create it.
  echo # Spacer.
  echo -n "[ ] Creating ${local_site_path}"
  mkdir $local_site_path
  echo -e "\r[${GREEN}\xE2\x9C\x94${NC}"
fi


# Move to host directory.
cd $local_site_path


# Setup clean local WP install.
if [[ -z "$update" ]] ; then
  echo -n "[ ] Deploying WordPress..."
  wp core download --locale=en_GB > /dev/null 2>&1 && wp config create --dbname=${PWD##*/} --dbuser=root --dbpass=root > /dev/null 2>&1 && wp db create --dbuser=root --dbpass=root > /dev/null 2>&1 && wp core install --url=${PWD##*/}.test --title=${PWD##*/} --admin_user=admin --admin_password=admin --admin_email=admin@${PWD##*/}.test > /dev/null 2>&1
  echo -e "\r[${GREEN}\xE2\x9C\x94${NC}"
fi


# Pull the live data in.
echo -n "[ ] Pulling down data... (be patient)"
# Pull wp-content.
if [[ -z "$update" || "$update" == "all" || "$update" == "content" ]] ; then
  rsync -az ${remote_server}:${VHOST_PATH}${remote_site}${WPCONTENT_PATH} ./ > /dev/null 2>&1
fi
# Pull db and search-replace inline.
if [[ -z "$update" || "$update" == "all" || "$update" == "database" ]] ; then
  # Update database prefix, in case not wp_.
  remote_site_prefix=$(ssh ${remote_server} "cd ${VHOST_PATH}${remote_site}${WPCONTENT_PATH} 2> /dev/null && wp config get table_prefix 2> /dev/null")
  wp config set table_prefix ${remote_site_prefix} > /dev/null 2>&1
  # Pull db + search/replace.
  ssh ${remote_server} "cd ${VHOST_PATH}${remote_site}${WPCONTENT_PATH} && wp search-replace '${remote_site_url}' 'http://${local_site}.test' --all-tables --export --skip-plugins --skip-themes 2> /dev/null" | wp db import --skip-plugins --skip-themes - > /dev/null 2>&1

  # Deactivate problematic plugins.
  wp plugin deactivate wppusher 2&> /dev/null ; wp plugin deactivate wp-super-cache 2&> /dev/null ; wp plugin deactivate w3-total-cache 2&> /dev/null ; wp plugin deactivate autoptimize 2&> /dev/null ; wp plugin deactivate cloudflare 2&> /dev/null ; wp plugin deactivate google-captcha 2&> /dev/null ; wp plugin deactivate better-wp-security 2&> /dev/null

  # Create temp admin user (repeats install conf as live has been db pulled in).
  wp user create admin admin@${local_site}.test --role=administrator --user_pass=admin > /dev/null 2>&1
fi
echo -e "\r[${GREEN}\xE2\x9C\x94${NC}"


# We are done.
echo -e "\n[${GREEN}\xE2\x9C\x94${NC}] ${GREEN}Done - you can now access ${local_site}.test in your browser.\nA new user 'admin' with password 'admin' has been created.\nOpening in your default browser now...${NC}"
sleep 3 ; valet open

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
