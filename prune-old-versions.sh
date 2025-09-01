#!/bin/bash

set -exu

# where this .sh file lives
DIRNAME=$(dirname "$0")
SCRIPT_DIR=$(cd "$DIRNAME" || exit 1; pwd)
cd "$SCRIPT_DIR" || exit 1

yq eval '.entries.eevee = [.entries.eevee[0]]' index.yaml -i
yq eval '.entries.eevee-bot = [.entries.eevee-bot[0]]' index.yaml -i
yq eval '.entries.eevee-operator = [.entries.eevee-operator[0]]' index.yaml -i
yq eval '.entries.eevee-crds = [.entries.eevee-crds[0]]' index.yaml -i
