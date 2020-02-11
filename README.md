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

## Usage
Running `clone.sh` will prompt for a few options, then copy the remote site into `~/Sites/xxx` and open your browser to https://xxx.test to view it. It also accepts a single argument `delete` which will attempt to cleanly remove local sites when you're finished with them.

## Updating / fixing valet
STUB:: In case of emergencies / problems, after debugging you can run `bash -c "$( curl -fsSL https://raw.githubusercontent.com/helpful/local_dev/master/uninstall.sh )"`, then follow with a re-install using the command above. This will preserve ~/Sites and databases, but always backup first.

## Updating clone.sh
If you want to update `clone.sh`, you can run `curl -o /usr/local/bin/clone.sh -fsSL https://raw.githubusercontent.com/helpful/local_dev/master/clone.sh ; chmod +x /usr/local/bin/clone.sh`

## Uninstalling
If you want to do a more thorough uninstall, including removing site files and databases, you can download and run the uninstall.sh script, tand run it passing the argument `nuke`.
- `curl -o uninstall.sh https://raw.githubusercontent.com/helpful/local_dev/master/uninstall.sh`
- `chmod +x uninstall.sh`
- `./uninstall.sh nuke`
