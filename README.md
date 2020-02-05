Local Dev
=============

## About
These scripts will setup a [Laravel Valet+](https://github.com/weprovide/valet-plus) and [WP CLI](https://wp-cli.org/) based local dev environment. [Homebrew](https://brew.sh) and [Composer](https://getcomposer.org/) will also be installed if not already.

## Install
**After** you have looked at the source and are happy, install by running `bash -c "$( curl -fsSL https://raw.githubusercontent.com/helpful/local_dev/master/install.sh )"`

This will install the dev environment, and make the script `clone.sh` available. Running `clone.sh` will prompt for a few options, then copy the remote site into `~/Sites/xxx` and open your browser to https://xxx.test to view it. It also accepts a single argument z`delete` which will attempt to cleanly remove local sites when you're finished with them.

## Updating
If you want to update `clone.sh`, you can run `curl -o /usr/local/bin/clone.sh -fsSL https://raw.githubusercontent.com/helpful/local_dev/master/clone.sh ; chmod +x /usr/local/bin/clone.sh`
