#!bash

GENERATED_CHARTS=(crds operator)
HANDWRITTEN_CHARTS=(bot eevee)

COMMIT="$(git rev-parse --short --verify main)"


# where this .sh file lives
DIRNAME=$(dirname "$0")
SCRIPT_DIR=$(cd "$DIRNAME" || exit 1; pwd)
cd "$SCRIPT_DIR" || exit 1

VERSIONS_SRC="${VERSIONS_SRC:-"$SCRIPT_DIR/versions.yaml"}" 
CHART_DIR="${CHART_DIR:-"$SCRIPT_DIR/charts"}"

function main() {
  cd "$SCRIPT_DIR" || exit 1
  setup_git_ci
  update_readme_gh_pages_branch
  setup_npm_ci

  echo "Cleanup"
  rm -rf charts/*
  rm -rf dist/*

  # generated charts
  echo "Run typescript build"
  npm ci
  npx tsc

  for CHART in "${GENERATED_CHARTS[@]}"; do
    echo "Processing chart: $CHART"

    cd dist || exit 1
    node "${CHART}.mjs"

    PRE_HELMIFY_HOOK="pre_helmify_hook_${CHART}"
    if declare -f "$PRE_HELMIFY_HOOK" > /dev/null; then
      echo "Calling pre-helmify hook function: $PRE_HELMIFY_HOOK"
      "$PRE_HELMIFY_HOOK"
    else
      echo "No pre-helmify hook function found for chart: $CHART"
    fi

    helmify -vv --original-name -f "manifests/${CHART}" "${CHART}"
    mkdir -pv "${CHART_DIR}/${CHART}"
    cp -R "${CHART}"/* "${CHART_DIR}/${CHART}"

    PRE_COMMIT_HOOK="pre_commit_hook_${CHART}"
    if declare -f "$PRE_COMMIT_HOOK" > /dev/null; then
      echo "Calling pre-commit hook function: $PRE_COMMIT_HOOK"
      "$PRE_COMMIT_HOOK"
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

    git add -v "${CHART_DIR}/${CHART}"
    git diff --quiet && git diff --staged --quiet || git commit -m "Build ${CHART} helmchart for commit ${COMMIT}"
  done

  for CHART in "${HANDWRITTEN_CHARTS[@]}"; do
    echo "Processing chart: $CHART"

    cd src || exit 1
    mkdir -pv "${CHART_DIR}/${CHART}"
    cp -R "${CHART}"/* "${CHART_DIR}/${CHART}"

    PRE_COMMIT_HOOK="pre_commit_hook_${CHART}"
    if declare -f "$PRE_COMMIT_HOOK" > /dev/null; then
      echo "Calling pre-commit hook function: $PRE_COMMIT_HOOK"
      "$PRE_COMMIT_HOOK"
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

    git add -v "${CHART_DIR}/${CHART}/*"
    git diff --quiet && git diff --staged --quiet || git commit -m "Build ${CHART} helmchart for commit ${COMMIT}"
  done

  # Update deps in eevee chart
  for CHART in "${GENERATED_CHARTS[@]}" "${HANDWRITTEN_CHARTS[@]}"; do
    echo "Updating version in eevee chart for ${CHART}"
    CHART_VERSION=$(yq e ".version" "${CHART_DIR}/${CHART}/Chart.yaml")
    export CHART
    export CHART_VERSION
    yq e -i '(.dependencies[] | select(.name == env(CHART)) | .version) = env(CHART_VERSION)' "${CHART_DIR}/eevee/Chart.yaml"
  done
  git add -v "${CHART_DIR}/eevee/*"
  git diff --quiet && git diff --staged --quiet || git commit -m "Update deps of ${CHART} helmchart for commit ${COMMIT}"

  finalize_git_ci
}

function finalize_git_ci() {
  cd "$SCRIPT_DIR" || exit 1
  echo "Updating gh-pages branch"
  cp -R "${CHART_DIR}" /tmp/charts
  git switch gh-pages
  cp -R /tmp/charts/* "${CHART_DIR}"/
  git add "${CHART_DIR}"/*
  git diff --quiet && git diff --staged --quiet || git commit -m "Update helmcharts on gh-pages branch for commit ${COMMIT}"
  git push

  echo "Git push main"
  git switch main
  git push
}

function setup_git_ci() {
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
  cd "$SCRIPT_DIR" || exit 1
  # npm install
  echo "Setup npm"
  echo "//npm.pkg.github.com/:_authToken=${GITHUB_TOKEN}" | tee -a "${HOME}/.npmrc"
  git switch main
  npm ci
}

function pre_helmify_hook_operator() {
  echo "noop"
  # yq e -i '(.spec.selector.matchLabels, .spec.template.metadata.labels, .spec.selector) |= with_entries(select(.key == "cdk8s.io/metadata.addr") | .key = "eevee.bot/operator")' dist/manifests/operator/eevee-operator.yaml
  # yq e -i '(.. | select(tag == "!!map" and has("eevee.bot/operator"))) |= (.["eevee.bot/operator"] = "true")' dist/manifests/operator/eevee-operator.yaml
}

main
