#! /bin/bash

# Usage: sh release.sh
# Note: To run this script locally you need to export environment variables CIRCLE_TAG and GITHUB_TOKEN.

# Stop script on first error
set -xe

FUTURE_RELEASE_SHA=$(hub rev-parse HEAD)
LATEST_RELEASE=$(hub release | head -n 1)
LATEST_RELEASE_SHA=$(hub rev-parse "${LATEST_RELEASE}")
LATEST_RELEASE_NEXT_COMMIT_SHA=$(hub log "${LATEST_RELEASE}"..HEAD --oneline --pretty=%H | tail -n1)
mkdir -p ./build/_output/docs/
release-notes --org mattermost --repo rotatorctl --start-sha "${LATEST_RELEASE_NEXT_COMMIT_SHA}" --end-sha "${FUTURE_RELEASE_SHA}"  --output ./build/_output/docs/relnote.md --required-author "" --branch main
cat ./build/_output/docs/relnote.md | sed '/docs.k8s.io/ d' | sed -e "s/\# Release notes for/${CIRCLE_TAG}/g" | sed -e "s/Changelog since/Changelog since ${LATEST_RELEASE}/g"> ./build/_output/docs/relnote_parsed.md
echo -e "\n" >> ./build/_output/docs/relnote_parsed.md
echo -e "_Thanks to all our contributors!_ \n" >> ./build/_output/docs/relnote_parsed.md
mv ./build/_output/docs/relnote_parsed.md ./build/_output/docs/relnote.md

make build && make build-mac
mv  ./build/_output/bin/rotatorctl ./build/_output/bin/rotatorctl-linux

hub release create -d -F ./build/_output/docs/relnote.md -a ./build/_output/bin/rotatorctl-linux -a ./build/_output/bin/rotatorctl-darwin ${CIRCLE_TAG}
rm -rf ./build/_output/