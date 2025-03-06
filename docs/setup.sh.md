

# setup.sh docs

## key requirements 

*concisely*

- [x] **Preserve project documentation files**
   - mv *.md to cd-template.docs/

- [x] **Properly handle hidden files**
   - cp -r .hidden-files/ .

- [x] **Set content at project root**
   - cp -r template/* .

- [x] **Preserve directory structure**
   - template dir structure is maintained *and* is in project root

- [x] **Provide user feedback**
   - guidance every step of the way
      - important since significant addition and changes to codebase

- [x] **Maintain backward compatibility**
   - same command interface
      - `gh init-cicd`, `gh fetch-cicd`, `gh list-cicd`


