#!/bin/bash
set -e

# Figure out where this script is located.
SELFDIR="`dirname \"$0\"`"
SELFDIR="`cd \"$SELFDIR\" && pwd`"

# Tell Bundler where the Gemfile and gems are.
export BUNDLE_GEMFILE="$SELFDIR/lib/vendor/Gemfile"
unset BUNDLE_IGNORE_CONFIG

cd "$SELFDIR/lib/app"

export PATH="$SELFDIR/lib/ruby/bin:$SELFDIR/lib/vendor/ruby/2.1.0/bin:$PATH"
if ! [ -e .devise-secret ];then
    hexdump -n 64 -v -e '/1 "%02X"' /dev/urandom > .devise-secret
fi
if ! [ -e .cookie-secret ];then
    hexdump -n 128 -v -e '/1 "%02X"' /dev/urandom > .cookie-secret
fi

export DEVISE_SECRET_KEY="$(cat .devise-secret)"
export SECRET_KEY_BASE="$(cat .cookie-secret)"
export PACKAGING=1 # prevent errors from missing development/test dependencies
export PACKAGED=1

if [ "$RAILS_ENV" == "" ];then
    export RAILS_ENV=production
fi

