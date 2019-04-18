#!/bin/bash
export SAUCE_USERNAME=okta-qa
export SAUCE_ACCESS_KEY="$(aws s3 --quiet --region us-east-1 cp s3://ci-secret-stash/prod/saucelabs/saucelabs_access_key /dev/stdout)"
export SAUCE_PLATFORM_NAME="iOS";

setup_service google-chrome-stable 66.0.3359.139-1

cd ${OKTA_HOME}/${REPO}

setup_service grunt

# Install required dependencies
npm install -g @okta/ci-update-package
npm install -g @okta/ci-pkginfo

if ! npm install --no-optional --unsafe-perm; then
  echo "npm install failed! Exiting..."
  exit ${FAILED_SETUP}
fi

function update_yarn_locks() {
    git checkout -- test/e2e/react-app/yarn.lock
    git checkout -- test/e2e/angular-app/yarn.lock

    YARN_REGISTRY=https://registry.yarnpkg.com
    OKTA_REGISTRY=${ARTIFACTORY_URL}/api/npm/npm-okta-master

    # Yarn does not utilize the npmrc/yarnrc registry configuration
    # if a lockfile is present. This results in `yarn install` problems
    # for private registries. Until yarn@2.0.0 is released, this is our current
    # workaround.
    #
    # Related issues:
    #  - https://github.com/yarnpkg/yarn/issues/5892
    #  - https://github.com/yarnpkg/yarn/issues/3330

    # Replace yarn artifactory with Okta's
    sed -i "s#${YARN_REGISTRY}#${OKTA_REGISTRY}#" test/e2e/react-app/yarn.lock
    sed -i "s#${YARN_REGISTRY}#${OKTA_REGISTRY}#" test/e2e/angular-app/yarn.lock
}


update_yarn_locks

if ! npm run test:e2e; then
  echo "e2e tests on iOS failed! Exiting..."
  exit ${FAILURE}
fi

exit ${SUCCESS}
