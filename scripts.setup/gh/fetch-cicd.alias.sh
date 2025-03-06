#!/bin/bash
# path: .\scripts.setup\gh\fetch-cicd.alias.sh

TEMPLATE="$1"

echo "Initializing template: $TEMPLATE"

      
      if [ -z \"\$1\" ]; then
          echo \"Error: No template specified\";
          echo \"Usage: gh fetch-cicd category/template\";
          exit 1;
      fi;

      echo \"Fetching template: \$TEMPLATE\";
      TMP_DIR=\$(mktemp -d);
      gh repo clone AlekOmOm/cicd-templates \"\$TMP_DIR\" || { echo \"Clone failed\"; exit 1; };
      TEMPLATE_PATH=\"\$TMP_DIR/templates/\$TEMPLATE\";
      if [ ! -d \"\$TEMPLATE_PATH\" ]; then
          echo \"Template not found: \$TEMPLATE_PATH\";
          exit 1;
      fi;
      echo \"Template found: \$TEMPLATE_PATH\";
      cp -r \"\$TEMPLATE_PATH\"/* .;
      
            
      # Copy template content from project root 
      # ./$TEMPLATE/*
      echo \"project root: \$(pwd)\";
      ls;
      
      # Copy template content to project root
      ## fx ./deploy/node/* -> .

      # print $1
      echo \"Parameters: \$1\";
      echo \"TEMPLATE VAR: \$1\";
      TEMPLATE_CONTENT_PATH=./\$TEMPLATE/;

      echo \"TEMPLATE_CONTENT_PATH: \$TEMPLATE_CONTENT_PATH\";
      TEMPLATE_CONTENT_PATH=./deploy/node/;
      
      #if [ -d \"\$TEMPLATE_CONTENT_PATH\" ]; then
          #cp -r \"\$TEMPLATE_CONTENT_PATH\"/* .;
      #fi;

      rm -rf \"\$TMP_DIR\";
  