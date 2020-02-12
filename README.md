Local Dev
=============

## About
These scripts will setup a [Laravel Valet+](https://github.com/weprovide/valet-plus) and [WP CLI](https://wp-cli.org/) based local dev environment. [Homebrew](https://brew.sh) and [Composer](https://getcomposer.org/) will also be installed if not already.

## Install
**After** you have looked at the source and are happy, install by running `bash -c "$( curl -fsSL https://raw.githubusercontent.com/helpful/local_dev/master/install.sh )"`

This will install the dev environment, and make the script `clone.sh` available.

### Install problems
- Composer error - conflicting symfony/console versions: resolve with `composer global require symfony/console "3.x" symfony/process "3.x"`, then re-run the install.
- - If this conflicts with other packages you might need to look at using consolidatino/cgr package to manage conflicts: https://github.com/weprovide/valet-plus/issues/318#issuecomment-473212202
- "Setting password for root user failed." warning: run `sudo mysqladmin -uroot password 'root'`
- Misc: do `brew services list` to see if dnsmasq, mariadb, nginx and valet-php@7.2 are all running. If not use `brew services start xxx` to start the missing ones. If needed `brew reinstall xxx` is sometimes needed if they won't start and you can't see another error.

## Usage
Running `clone.sh` will prompt for a few options, then copy the remote site into `~/Sites/xxx` and open your browser to https://xxx.test to view it. It also accepts a single argument `delete` which will attempt to cleanly remove local sites when you're finished with them.

## Updating / fixing valet
STUB:: In case of emergencies / problems, after debugging you can run `bash -c "$( curl -fsSL https://raw.githubusercontent.com/helpful/local_dev/master/uninstall.sh )"`, restart your machine, then follow with a re-install using the command above. This will preserve ~/Sites and databases, but always backup first.
Note - this isn't seamless, Nginx config files are delete which means you will need to run `valet secure` in each relevant Sites/* directory to turn on SSL again, and also the 'load image from live' code is lost. Ideally use `clone.sh delete` to remove a site and start again, or `clone.sh` and option 5 to re-clone/set it up from scratch.

## Updating clone.sh
If you want to update `clone.sh`, you can run `curl -o /usr/local/bin/clone.sh -fsSL https://raw.githubusercontent.com/helpful/local_dev/master/clone.sh ; chmod +x /usr/local/bin/clone.sh`

## Uninstalling
If you want to do a more thorough uninstall, including removing site files and databases, you can download the uninstall.sh script, and run it passing the argument `nuke`.
- `curl -o uninstall.sh https://raw.githubusercontent.com/helpful/local_dev/master/uninstall.sh`
- `chmod +x uninstall.sh`
- `./uninstall.sh nuke`
- restart your machine
