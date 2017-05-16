#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

source state/env.sh
true ${CF_API_URL:?"!"}
true ${CF_USERNAME:?"!"}
true ${CF_PASSWORD:?"!"}
true ${CF_ORG:?"!"}
true ${CF_SPACE:?"!"}

if ! [ -f cakeshop.war ]; then
  curl -L "https://github.com/jpmorganchase/cakeshop/releases/download/0.9.1/cakeshop-0.9.1-x86_64-linux.war" > cakeshop.war
fi

if ! cf apps; then
  cf login -a $CF_API_URL -u $CF_USERNAME -p $CF_PASSWORD -o $CF_ORG -s $CF_SPACE
fi

cf push

cf allow-access bmm-cakeshop bmm-cakeshop2 --port 30303 --protocol tcp
cf allow-access bmm-cakeshop2 bmm-cakeshop --port 30303 --protocol tcp

