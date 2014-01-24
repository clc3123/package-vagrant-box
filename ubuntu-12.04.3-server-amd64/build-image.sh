#!/bin/bash

export PACKAGING_DATE=$(date +%F)
sed '/^[[:space:]]*\/\//d' template.json | packer build --force -
