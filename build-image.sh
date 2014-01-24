#!/bin/bash

sed '/^[[:space:]]*\/\//d' template.json | packer build --debug --force -
