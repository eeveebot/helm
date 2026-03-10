#!bash

GENERATED_CHARTS=(crds operator)
HANDWRITTEN_CHARTS=(bot eevee)

COMMIT="$(git rev-parse --short --verify main)"

# where this .sh file lives
DIRNAME=$(dirname "$0")
SCRIPT_DIR=$(cd "$DIRNAME" || exit 1; pwd)
cd "$SCRIPT_DIR" || exit 1

# git setup
echo "Setup git"
git config --global --add safe.directory "$(pwd)"
git config user.name "${GITHUB_ACTOR}"
git config user.email "${GITHUB_ACTOR}@users.noreply.github.com"
git fetch
git pull

# npm install
echo "Setup npm"
echo "//npm.pkg.github.com/:_authToken=${GITHUB_TOKEN}" | tee -a "${HOME}/.npmrc"
git switch main
npm ci
git reset --hard

# update readme
echo "Update readme"
git switch main
cp README.md /tmp/README.md
git switch gh-pages
cp -v /tmp/README.md README.md
git add --verbose README.md
git diff --quiet && git diff --staged --quiet || git commit -m "Update README.md for commit ${COMMIT}"
git switch main

# generated charts
echo "Run typescript build"
npx tsc

git diff --quiet && git diff --staged --quiet || git commit -m "Build Helmcharts for commit ${COMMIT}"

for CHART in "${GENERATED_CHARTS[@]}"; do
  echo "Processing chart: $CHART"

  cd dist && node "${CHART}.mjs"
  bash set-version.sh "${CHART}" ./charts ./versions.yaml

  HOOK_FUNCTION="hook_${CHART}"
  if declare -f "$HOOK_FUNCTION" > /dev/null; then
    echo "Calling hook function: $HOOK_FUNCTION"
    "$HOOK_FUNCTION"
  else
    echo "No hook function found for chart: $CHART"
  fi
done

function hook_crds() {
  # no-op... for now
}

function hook_operator() {
  yq e -i '(.spec.selector.matchLabels, .spec.template.metadata.labels, .spec.selector) |= with_entries(select(.key == "cdk8s.io/metadata.addr") | .key = "eevee.bot/operator")' dist/manifests/operator/eevee-operator.yaml
  yq e -i '(.. | select(tag == "!!map" and has("eevee.bot/operator"))) |= (.["eevee.bot/operator"] = "true")' dist/manifests/operator/eevee-operator.yaml
}
