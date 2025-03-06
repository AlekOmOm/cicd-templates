#!/bin/bash
## ./scripts.setup/gh/init-cicd.alias.sh

TEMPLATE="$1"

echo "Initializing template: $TEMPLATE"

gh fetch-cicd "$TEMPLATE" && \
if [ -f ./CD-*.template-setup.sh ]; then
    chmod +x ./CD-*.template-setup.sh && ./CD-*.template-setup.sh
fi
