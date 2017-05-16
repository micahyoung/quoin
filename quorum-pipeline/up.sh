#!/bin/bash
set -o errexit
set -o nounset
set -o pipefail

if ! [ -d state/ ]; then
  exit "No State, exiting"
  exit 1
fi

source state/env.sh
true ${CONCOURSE_TARGET:?"env!"}
true ${CONCOURSE_PIPELINE:?"env!"}
true ${CONCOURSE_DOMAIN:?"env!"}
true ${STATE_REPO_URL:?"env!"}
true ${STATE_REPO_PRIVATE_KEY:?"env!"}
true ${APP_REPO_URL:?"env!"}
true ${CF_API_URL:?"env!"}
true ${CF_USERNAME:?"env!"}
true ${CF_PASSWORD:?"env!"}
true ${CF_ORG:?"env!"}
true ${CF_SPACE:?"env!"}
true ${PIPELINE_REPO_URL:?"env!"}
true ${STATE_REPO_URL:?"env!"}
true ${STATE_REPO_PRIVATE_KEY:?"env!"}

mkdir -p bin
PATH=$(pwd)/bin:$PATH

if ! [ -f bin/fly ]; then
  curl -L "http://$CONCOURSE_DOMAIN/api/v1/cli?arch=amd64&platform=darwin" > bin/fly
  chmod +x bin/fly
fi

if ! fly targets | grep $CONCOURSE_TARGET; then
  fly login \
    --target $CONCOURSE_TARGET \
    --concourse-url "https://$CONCOURSE_DOMAIN" \
    --username $CONCOURSE_USERNAME \
    --password $CONCOURSE_PASSWORD \
  ;
fi

if ! [ -f state/quorum-pipeline-vars.yml ]; then
  cat > state/quorum-pipeline-vars.yml <<EOF
cf_api_url: $CF_API_URL
cf_username: $CF_USERNAME
cf_password: $CF_PASSWORD
cf_org: $CF_ORG
cf_space: $CF_SPACE
pipeline_repo_url: $PIPELINE_REPO_URL
state_repo_url: $STATE_REPO_URL
state_repo_private_key: !!binary $(echo $STATE_REPO_PRIVATE_KEY | base64)
EOF
fi

if ! fly pipelines -t $CONCOURSE_TARGET | grep $CONCOURSE_PIPELINE; then
  fly set-pipeline \
    --target $CONCOURSE_TARGET \
    --pipeline $CONCOURSE_PIPELINE \
    --load-vars-from state/quorum-pipeline-vars.yml \
    --config quorum-pipeline.yml \
    --non-interactive \
  ;
fi
