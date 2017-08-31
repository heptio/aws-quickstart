#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

cd "$(dirname "$0")/.."

for t in ./ci/tests/*; do
    "${t}"
done
