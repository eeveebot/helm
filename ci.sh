#!bash

GENERATED_CHARTS=(crds operator)
HANDWRITTEN_CHARTS=(bot eevee)

COMMIT="$(git rev-parse --short --verify main)"

# Check if we're running in GitHub CI/CD environment
IS_GITHUB_CI=false
if [[ -n "$GITHUB_ACTIONS" ]]; then
  IS_GITHUB_CI=true
fi

# where this .sh file lives
DIRNAME=$(dirname "$0")
SCRIPT_DIR=$(cd "${DIRNAME}" || exit 1; pwd)
cd "${SCRIPT_DIR}" || exit 1

VERSIONS_SRC="${VERSIONS_SRC:-"$SCRIPT_DIR/versions.yaml"}"
CHART_DIR="${CHART_DIR:-"$SCRIPT_DIR/charts"}"

function main() {
  cd "$SCRIPT_DIR" || exit 1

  if [[ "$IS_GITHUB_CI" == true ]]; then
    setup_git_ci
    update_readme_gh_pages_branch
    setup_npm_ci
  else
    echo "Running in local environment - skipping CI setup functions"
  fi

  echo "Cleanup"
  rm -rf charts/*
  rm -rf dist/*

  # generated charts
  echo "Run typescript build"
  if [[ "$IS_GITHUB_CI" == true ]]; then
    npm ci
  else
    echo "Skipping npm ci in local environment"
  fi
  npx tsc

  for CHART in "${GENERATED_CHARTS[@]}"; do
    echo "Processing chart: $CHART"

    cd dist || exit 1
    node "${CHART}.mjs"

    PRE_HELMIFY_HOOK="pre_helmify_hook_${CHART}"
    if declare -f "$PRE_HELMIFY_HOOK" > /dev/null; then
      echo "Calling pre-helmify hook function: $PRE_HELMIFY_HOOK"
      (cd "${SCRIPT_DIR}" && "$PRE_HELMIFY_HOOK")
    else
      echo "No pre-helmify hook function found for chart: $CHART"
    fi

    helmify -vv --original-name -f "manifests/${CHART}" "${CHART}"
    mkdir -pv "${CHART_DIR}/${CHART}"
    cp -R "${CHART}"/* "${CHART_DIR}/${CHART}"

    PRE_COMMIT_HOOK="pre_commit_hook_${CHART}"
    if declare -f "$PRE_COMMIT_HOOK" > /dev/null; then
      echo "Calling pre-commit hook function: $PRE_COMMIT_HOOK"
      (cd "${SCRIPT_DIR}" && "$PRE_COMMIT_HOOK")
    else
      echo "No pre-commit hook function found for chart: $CHART"
    fi

    cd "${SCRIPT_DIR}" || exit 1

    # Update the chart versions/description
    DESCRIPTION=$(yq eval ".${CHART}.description" $VERSIONS_SRC)
    CHART_VERSION=$(yq eval ".${CHART}.chart" $VERSIONS_SRC)
    APP_VERSION=$(yq eval ".${CHART}.application" $VERSIONS_SRC)
    yq e -i ".description = \"${DESCRIPTION}\"" "${CHART_DIR}/${CHART}/Chart.yaml"
    yq e -i ".version = \"${CHART_VERSION}\"" "${CHART_DIR}/${CHART}/Chart.yaml"
    yq e -i ".appVersion = \"${APP_VERSION}\"" "${CHART_DIR}/${CHART}/Chart.yaml"

    if [[ "$IS_GITHUB_CI" == true ]]; then
      git add -v "${CHART_DIR}/${CHART}"
      git diff --quiet && git diff --staged --quiet || git commit -m "Build ${CHART} helmchart for commit ${COMMIT}"
    else
      echo "Skipping git operations in local environment"
    fi
  done

  for CHART in "${HANDWRITTEN_CHARTS[@]}"; do
    echo "Processing chart: $CHART"

    cd src || exit 1
    mkdir -pv "${CHART_DIR}/${CHART}"
    cp -R "${CHART}"/* "${CHART_DIR}/${CHART}"

    PRE_COMMIT_HOOK="pre_commit_hook_${CHART}"
    if declare -f "$PRE_COMMIT_HOOK" > /dev/null; then
      echo "Calling pre-commit hook function: $PRE_COMMIT_HOOK"
      (cd "${SCRIPT_DIR}" && "$PRE_COMMIT_HOOK")
    else
      echo "No pre-commit hook function found for chart: $CHART"
    fi

    cd "${SCRIPT_DIR}" || exit 1

    # Update the chart versions/description
    DESCRIPTION=$(yq eval ".${CHART}.description" $VERSIONS_SRC)
    CHART_VERSION=$(yq eval ".${CHART}.chart" $VERSIONS_SRC)
    APP_VERSION=$(yq eval ".${CHART}.application" $VERSIONS_SRC)
    yq e -i ".description = \"${DESCRIPTION}\"" "${CHART_DIR}/${CHART}/Chart.yaml"
    yq e -i ".version = \"${CHART_VERSION}\"" "${CHART_DIR}/${CHART}/Chart.yaml"
    yq e -i ".appVersion = \"${APP_VERSION}\"" "${CHART_DIR}/${CHART}/Chart.yaml"

    if [[ "$IS_GITHUB_CI" == true ]]; then
      git add -v "${CHART_DIR}/${CHART}/*"
      git diff --quiet && git diff --staged --quiet || git commit -m "Build ${CHART} helmchart for commit ${COMMIT}"
    else
      echo "Skipping git operations in local environment"
    fi
  done

  # Update deps in eevee chart
  for CHART in "${GENERATED_CHARTS[@]}" "${HANDWRITTEN_CHARTS[@]}"; do
    echo "Updating version in eevee chart for ${CHART}"
    CHART_VERSION=$(yq e ".version" "${CHART_DIR}/${CHART}/Chart.yaml")
    export CHART
    export CHART_VERSION
    yq e -i '(.dependencies[] | select(.name == env(CHART)) | .version) = env(CHART_VERSION)' "${CHART_DIR}/eevee/Chart.yaml"
  done

  if [[ "$IS_GITHUB_CI" == true ]]; then
    echo "Bumping eevee chart version"
    CHART_VERSION=$(yq e '.eevee.chart' $VERSIONS_SRC)
    APP_VERSION=$(yq e '.eevee.application' $VERSIONS_SRC)

    # Increment patch version
    NEW_CHART_VERSION=$(echo "$CHART_VERSION" | awk -F. '{print $1"."$2"."$3+1}')
    if [ $? -ne 0 ] || [ -z "$NEW_CHART_VERSION" ]; then
      echo "Error: Failed to increment chart version"
      exit 1
    fi
    NEW_APP_VERSION="$NEW_CHART_VERSION"

    # Update versions.yaml
    yq e -i '.eevee.chart = "'"$NEW_CHART_VERSION"'"' $VERSIONS_SRC
    yq e -i '.eevee.application = "'"$NEW_APP_VERSION"'"' $VERSIONS_SRC

    # Update eevee chart Chart.yaml
    yq e -i '.version = "'"$NEW_CHART_VERSION"'"' "${CHART_DIR}/eevee/Chart.yaml"
    yq e -i '.appVersion = "'"$NEW_APP_VERSION"'"' "${CHART_DIR}/eevee/Chart.yaml"

    echo "Adding eevee chart to git staged and committing"
    git add "${CHART_DIR}/eevee/*"
    git diff --quiet && git diff --staged --quiet || git commit -m "Update deps of eevee helmchart for commit ${COMMIT}"
  else
    echo "Skipping git operations in local environment"
  fi

  if [[ "$IS_GITHUB_CI" == true ]]; then
    finalize_git_ci
  else
    echo "Skipping finalize_git_ci in local environment"
  fi
}

function finalize_git_ci() {
  if [[ "$IS_GITHUB_CI" != true ]]; then
    echo "Skipping finalize_git_ci in local environment"
    return
  fi

  cd "$SCRIPT_DIR" || exit 1
  echo "Updating gh-pages branch"
  cp -R "${CHART_DIR}" /tmp/charts
  git switch gh-pages
  mkdir -pv "${CHART_DIR}"
  cp -R /tmp/charts/* "${CHART_DIR}"/
  git add "${CHART_DIR}"/*
  git diff --quiet && git diff --staged --quiet || git commit -m "Update helmcharts on gh-pages branch for commit ${COMMIT}"
  git push

  echo "Git push main"
  git switch main
  git push
}

function setup_git_ci() {
  if [[ "$IS_GITHUB_CI" != true ]]; then
    echo "Skipping setup_git_ci in local environment"
    return
  fi

  cd "$SCRIPT_DIR" || exit 1
  # git setup
  echo "Setup git"
  git config --global --add safe.directory "$(pwd)"
  git config user.name "${GITHUB_ACTOR}"
  git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
  git fetch
  git pull
}

function update_readme_gh_pages_branch() {
  if [[ "$IS_GITHUB_CI" != true ]]; then
    echo "Skipping update_readme_gh_pages_branch in local environment"
    return
  fi

  cd "$SCRIPT_DIR" || exit 1
  # update readme
  echo "Update readme"
  git switch main
  cp README.md /tmp/README.md
  git switch gh-pages
  cp -v /tmp/README.md README.md
  git add --verbose README.md
  git diff --quiet && git diff --staged --quiet || (git commit -m "Update README.md for commit ${COMMIT}" && git push)
  git switch main
}

function setup_npm_ci() {
  if [[ "$IS_GITHUB_CI" != true ]]; then
    echo "Skipping setup_npm_ci in local environment"
    return
  fi

  cd "$SCRIPT_DIR" || exit 1
  # npm install
  echo "Setup npm"
  echo "//npm.pkg.github.com/:_authToken=${GITHUB_TOKEN}" >> "${HOME}/.npmrc"
  git switch main
  npm ci
}

function pre_helmify_hook_operator() {
  yq e -i '(.spec.selector.matchLabels, .spec.template.metadata.labels, .spec.selector) |= with_entries(select(.key == "cdk8s.io/metadata.addr") | .key = "eevee.bot/operator")' dist/manifests/operator/eevee-operator.yaml
  yq e -i '(.. | select(tag == "!!map" and has("eevee.bot/operator"))) |= (.["eevee.bot/operator"] = "true")' dist/manifests/operator/eevee-operator.yaml
  yq e -i '(select(.kind == "Deployment" and .metadata.name == "operator") | .spec.selector) |= {"matchLabels": {"eevee.bot/operator": "true"}}' dist/manifests/operator/eevee-operator.yaml
}

main
