#!/bin/bash

#
# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.
#

set -e
set +x

# Two stage script: first it compiles using node docker container,
# then it runs itself from within another docker container to deploys to GCP

# Usage:
# * Compile and deploy:          ./deployStaging.sh
# * Deploy only without docker:  ./deployStaging.sh nodocker

# Expected env variables:
# * GPROJECT - "elastic-ems-prod" or "elastic-ems-dev"
# * GCE_ACCOUNT - credentials for the google service account (JSON blob)
# * GIT_BRANCH - current GIT branch (e.g. "refs/heads/master")

if [[ -z "${GPROJECT}" ]]; then
    echo "GPROJECT is not set, e.g. 'GPROJECT=elastic-ems-prod'"
    exit 1
fi
if [[ -z "${GCE_ACCOUNT}" ]]; then
    echo "GCE_ACCOUNT is not set. Expected google service account JSON blob."
    exit 1
fi
if [[ -z "${GIT_BRANCH}" ]]; then
    echo "GIT_BRANCH is not set, e.g. 'GIT_BRANCH=refs/heads/master'"
    exit 1
fi


if [[ "$1" != "nodocker" ]]; then

    ./build.sh

    # Run this script from inside the docker container, using google/cloud-sdk image
    echo "Deploying to staging environment"
    docker run \
        --rm -i \
        --env GCE_ACCOUNT \
        --env GIT_BRANCH \
        --env GPROJECT \
        --env HOME=/tmp \
        --volume $PWD:/app \
        --user=$(id -u):$(id -g) \
        --workdir /app \
        'google/cloud-sdk:slim' \
        /app/deployStaging.sh nodocker "$@"
    unset GCE_ACCOUNT

else

    # Copying files to the staging environment
    # Login to the cloud with the service account
    gcloud auth activate-service-account --key-file <(echo "$GCE_ACCOUNT")
    unset GCE_ACCOUNT


    # master branch goes into root, specific branches go into properly named dirs
    # The trailing slash is critical with the branch.
    # Otherwise, files from subdirs will go to the same destination dir.
    if [[ "$GIT_BRANCH" == "origin/master" ]]; then
        URL_PATH=""
    else
        # remove remote "origin/", leaving just the branch name plus a slash '/'
        URL_PATH="${GIT_BRANCH#*/}/"
    fi


    # Copy files
    EMS_PROJECT=landing-page
    STAGING_BUCKET=${GPROJECT}-${EMS_PROJECT}-staging
    echo "Copying $PWD/release/* to gs://$STAGING_BUCKET/$URL_PATH"
    gsutil -m cp -r -a public-read -z js,css,html "$PWD/build/release/*" "gs://$STAGING_BUCKET/$URL_PATH"

fi
