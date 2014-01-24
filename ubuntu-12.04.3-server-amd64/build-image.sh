#!/bin/bash

export PACKAGING_DATE=$(date +%Y%m%d)
sed '/^[[:space:]]*\/\//d' template.json | packer build --force -
