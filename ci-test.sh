#!bash

GENERATED_CHARTS=(crds operator)
HANDWRITTEN_CHARTS=(bot eevee)

COMMIT="$(git rev-parse --short --verify main)"

# where this .sh file lives
DIRNAME=$(dirname "$0")
SCRIPT_DIR=$(cd "${DIRNAME}" || exit 1; pwd)
cd "${SCRIPT_DIR}" || exit 1

function main() {
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
    mkdir -pv "${SCRIPT_DIR}/charts/${CHART}"
    cp -R "${CHART}"/* "${SCRIPT_DIR}/charts/${CHART}"

    PRE_COMMIT_HOOK="pre_commit_hook_${CHART}"
    if declare -f "$PRE_COMMIT_HOOK" > /dev/null; then
      echo "Calling pre-commit hook function: $PRE_COMMIT_HOOK"
      "$PRE_COMMIT_HOOK"
    else
      echo "No pre-commit hook function found for chart: $CHART"
    fi

    cd "${SCRIPT_DIR}" || exit 1
    bash set-version.sh "${CHART}"
    git add -v "charts/${CHART}"
    git diff --quiet && git diff --staged --quiet || git commit -m "Build ${CHART} helmchart for commit ${COMMIT}"
  done

  for CHART in "${HANDWRITTEN_CHARTS[@]}"; do
    echo "Processing chart: $CHART"

    cd src || exit 1
    mkdir -pv "${SCRIPT_DIR}/charts/${CHART}"
    cp -R "${CHART}"/* "${SCRIPT_DIR}/charts/${CHART}"

    PRE_COMMIT_HOOK="pre_commit_hook_${CHART}"
    if declare -f "$PRE_COMMIT_HOOK" > /dev/null; then
      echo "Calling pre-commit hook function: $PRE_COMMIT_HOOK"
      "$PRE_COMMIT_HOOK"
    else
      echo "No pre-commit hook function found for chart: $CHART"
    fi

    cd "${SCRIPT_DIR}" || exit 1
    bash set-version.sh "${CHART}"
    git add -v "charts/${CHART}/*"
    git diff --quiet && git diff --staged --quiet || git commit -m "Build ${CHART} helmchart for commit ${COMMIT}"
  done

  # Update deps in eevee chart
  for CHART in "${GENERATED_CHARTS[@]} ${HANDWRITTEN_CHARTS[@]}"; do
    echo "Updating version in eevee chart for ${CHART}"
    CHART_VERSION=$(yq e ".${CHART}.chart" versions.yaml)
    export CHART
    export CHART_VERSION
    yq e -i '(.dependencies[] | select(.name == env(CHART)) | .version) = env(CHART_VERSION)' "${SCRIPT_DIR}/charts/eevee/Chart.yaml"
  done
  git add -v "charts/eevee/*"
  git diff --quiet && git diff --staged --quiet || git commit -m "Update deps of ${CHART} helmchart for commit ${COMMIT}"
}

function pre_helmify_hook_operator() {
  echo "noop"
  # yq e -i '(.spec.selector.matchLabels, .spec.template.metadata.labels, .spec.selector) |= with_entries(select(.key == "cdk8s.io/metadata.addr") | .key = "eevee.bot/operator")' dist/manifests/operator/eevee-operator.yaml
  # yq e -i '(.. | select(tag == "!!map" and has("eevee.bot/operator"))) |= (.["eevee.bot/operator"] = "true")' dist/manifests/operator/eevee-operator.yaml
}

main
