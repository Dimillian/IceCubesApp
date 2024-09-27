#!/bin/sh

set -e

if [[ "$CI_WORKFLOW" != "EmergeTools Upload" ]]; then
    exit 0
fi

required_env_vars=(
    "CI_ARCHIVE_PATH"
    "CI_BRANCH"
    "CI_COMMIT"
    "EMERGE_API_KEY"
)

brew install jq

zip_path="$CI_ARCHIVE_PATH.zip"
pushd $(dirname $CI_ARCHIVE_PATH)
zip -r --symlinks "$(basename $zip_path)" "$(basename $CI_ARCHIVE_PATH)"
popd

repo_name='Dimillian/IceCubesApp'
tag='release'
json_fields=$(cat <<EOF
"filename":"${zip_path}",
"branch":"${CI_BRANCH}",
"sha":"${CI_COMMIT}",
"repoName":"${repo_name}",
"tag":"${tag}"
EOF
)

if [[ -n "${CI_PULL_REQUEST_NUMBER}" ]]; then
    pr_required_env_vars=(
        "CI_PULL_REQUEST_NUMBER"
        "CI_PULL_REQUEST_TARGET_COMMIT"
    )

    for var in "${pr_required_env_vars[@]}"; do
        if [[ -z "${!var}" ]]; then
            echo "Environment variable $var is not set"
            exit 1
        fi
    done

    json_fields=$(cat <<EOF
${json_fields},
"prNumber":"${CI_PULL_REQUEST_NUMBER}",
"baseSha":"${CI_PULL_REQUEST_TARGET_COMMIT}"
EOF
    )
fi

upload_response=$(curl \
    --url "https://api.emergetools.com/upload" \
    --header 'Accept: application/json' \
    --header 'Content-Type: application/json' \
    --header "X-API-Token: $EMERGE_API_KEY" \
    --data "{$json_fields}")

# Pull the uploadURL field from the response using jq
upload_url=$(echo "$upload_response" | jq -r .uploadURL)

curl -v -H 'Content-Type: application/zip' -T "$zip_path" "$upload_url"
