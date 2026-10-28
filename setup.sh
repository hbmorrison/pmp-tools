#!/bin/bash

# Configuration.

APT_PACKAGES="ruby ruby-ffi ruby-json ruby-zip"
DNF_PACKAGES="ruby rubygem-ffi rubygem-json rubygem-rubyzip"

# Only install gems that are not available as system packages.

RUBY_GEMS="rest-client"

# Pretty feedback.

GOTO_COLUMN="\\033[72G"
COLOUR_RED='\033[00;31m'
COLOUR_YELLOW='\033[00;33m'
COLOUR_GREEN='\033[00;32m'
COLOUR_CLEAR='\033[00m'

pass () {
  echo -e "${GOTO_COLUMN}${COLOUR_GREEN}Done${COLOUR_CLEAR}"
}

fail () {
  if [ ! -z ${1:+z} ]
  then
    echo -e "${GOTO_COLUMN}${COLOUR_RED}Failed${COLOUR_CLEAR}"
    echo -e "${COLOUR_RED}Error:${COLOUR_CLEAR} ${1}"
    exit 1
  else
    echo -e "${GOTO_COLUMN}${COLOUR_YELLOW}Failed${COLOUR_CLEAR}"
    return 1
  fi
}

# Locate the base directory of the repository.

SCRIPT_PATH=$(readlink -f $0)
BASE_DIR=$(dirname $SCRIPT_PATH)

# Work out whether to run commands using sudo.

echo -n "Checking sudo access... "
if sudo -n /bin/true 2>/dev/null
then
  pass
else
  fail
  sudo -v
  echo -n "Checking sudo access again... "
  sudo -n /bin/true 2>/dev/null && pass || fail "no sudo access"
fi

# Check whether the bash script is being sourced from the .bashrc file.

if ! grep -q 'source.*\.bashrc_pmp' ~/.bashrc
then
  echo -n "Adding section to source .bashrc_pmp into .bashrc... "
  cat $BASE_DIR/etc/bashrc_section >> ~/.bashrc && pass || fail
fi

# Work out how to install required packages.

source /etc/os-release

echo -n "Getting package manager commands... "
case $ID in
  debian|ubuntu)
    ALL_PACKAGES=$APT_PACKAGES
    PACKAGE_CHECK_CMD='/bin/dpkg-query -W'
    UPDATE_CMD='/bin/apt update -y'
    INSTALL_CMD='/bin/apt install -y'
    ;;
  fedora|rocky)
    ALL_PACKAGES=$DNF_PACKAGES
    PACKAGE_CHECK_CMD='/bin/rpm -q'
    INSTALL_CMD='/sbin/dnf install -y'
    ;;
  *)
    fail "operating system ${ID} not recognised"
    ;;
esac
pass

# Work out what packages need to be installed.

PACKAGES=""
for PACKAGE in $ALL_PACKAGES
do
  if ! $PACKAGE_CHECK_CMD $PACKAGE &>/dev/null
  then
    PACKAGES="${PACKAGES} ${PACKAGE}"
  fi
done

# Install any packages that are missing.

if [ ! -z ${PACKAGES:+z} ]
then
  if [ ! -z ${UPDATE_CMD:+z} ]
  then
    echo -n "Updating package lists... "
    sudo $UPDATE_CMD &>/dev/null && pass || fail
  fi
  if [ ! -z ${INSTALL_CMD:+z} ]
  then
    echo -n "Installing required packages... "
    sudo $INSTALL_CMD $PACKAGES &>/dev/null && pass || fail
  fi
fi

# Work out what additional ruby gems need to be installed.

GEMS=""
for GEM in $RUBY_GEMS
do
  if ! gem list --local "${GEM}" | grep "^${GEM}" &>/dev/null
  then
    GEMS="${GEMS} ${GEM}"
  fi
done

# Install any gems that are missing.

if [ ! -z ${GEMS:+z} ]
then
  echo -n "Installing ruby gems... "
  sudo gem install $GEMS &>/dev/null && pass || fail
fi

# Create any directories that are needed.

echo -n "Creating directories in ${HOME}... "
for DIR in $(cd $BASE_DIR; find . -type d -not -path "."  | sed  's#^./##')
do
  case $DIR in

    # Ignore the git directory.

    \.git) ;;
    \.git/*) ;;

    # Ignore the etc directory.

    etc) ;;
    etc/*) ;;

    # Create other directories under the home directory.

    *)
      if [ ! -d "${HOME}/.${DIR}" ]
      then
        mkdir "${HOME}/.${DIR}" &>/dev/null \
         || fail "could not create directory .${DIR} in ${HOME}"
      fi
      ;;
  esac
done
pass

# Copy the files.

echo -n "Copying files into ${HOME}... "
for ITEM in $(cd $BASE_DIR; find . -type f  | sed  's#^./##')
do
  case $ITEM in

    # Ignore the git files.

    \.git/*) ;;
    \.git*) ;;

    # Ignore the files in the etc directory.

    etc/*) ;;

    # Ignore the README and the setup script.

    README.md) ;;
    setup.sh) ;;

    # Copy everything else.

    *)
      cp $BASE_DIR/$ITEM "$HOME/.${ITEM}" &>/dev/null \
       || fail "could not copy ${ITEM} into ${HOME}" ;;
  esac
done
pass
