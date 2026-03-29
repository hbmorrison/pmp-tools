# Password Manager Pro Tools

This repository contains some shell configuration files that integrate Password
Manager Pro password lookups with the command-line ssh command.

## Prerequisites

The PMP tools currently work on Debian and Ubuntu WSL distributions, and require
the following packages to be installed:

- `ruby`
- `ruby-ffi`
- `ruby-json`
  `ruby-rest-client`

## Configuration

### Shell configuration

The `setup.sh` script will install the prerequisites and copy some configuration
files into your home directory.

If you run:

```shell
$ ./setup.sh append
```

The script will also append the required sections to your shell configuration
files. Otherwise, run `setup.sh` with no arguments then edit your `.bashrc` file
and append the following:

```shell
if [ -r "${HOME}/.bashrc_pmp" ]
then
  source $HOME/.bashrc_pmp
fi
```

### Password Manager Pro configuration

Create a new API user for your PC in Password Manager Pro:

- login to Password Manager Pro
- click the Quick Links button and select Users
- click on Add User and select Add API User
- enter `<uun>_sausages.cache_api` for the username
- enter `sausages.cache.ed.ac.uk` for the host name
- enter your full name followed by "sausages.cache API"
- enter your email address
- select Enable Now
- click Generate and make a note of the auth token
- click Save

Then add the new API user to the `API_read_all` group:

- click on the user icon next to the new API user
- select Add User to Multiple Groups
- find the `API_read_all` group on the left
- click on the right arrow
- click Save

Back in WSL, create a file called `.pmp_api_auth_token` in your home directory
and paste the auth token for the new API user into it.

Then protect the file:

```shell
$ chmod 400 ~/.pmp_api_auth_token
```

## Usage

The `.bashrc_pmp` script defines a function called `ssh` that bash will call
preferentially over the ssh binary located on the filesystem. The ssh binary can
still be accessed with `command ssh` or by using the full path to the
executable.

The `ssh` function takes the hostname and optionally a username from the
arguments:

```shell
ssh [username@]<host>[.fqdn]
```

The `isapps` user will be used if a username is not specified and, if a short
hostname is specified, the `is.ed.ac.uk` domain will be appended to it. For
example:

```shell
$ ssh python-at1-dev
```

Will find the `python-at1-dev` resource, copy the `isapps` password from the
resource into the clipboard and then ssh to `isapps@python-at1-dev.is.ed.ac.uk`.

To counteract poor resource naming in PMP, the `pmp_lookup` code will make
several searches using different fuzzy search patterns in an attempt to find the
correct password. If a particular resource cannot be found despite this fuzzy
searching, there may be a case for finding the resource in PMP and improving its
name.
