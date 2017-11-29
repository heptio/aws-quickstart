#!/bin/bash

for instance in $(echo "$(aws ec2 describe-spot-price-history help)" | grep -e "^[\t ]*[a-z][0-9]\." | tr -d ' '); do
    echo "    - ${instance}"
done
