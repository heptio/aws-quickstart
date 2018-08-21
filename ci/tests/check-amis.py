#!/usr/bin/env python3

"""
Copyright 2017 by the contributors

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
"""

import sys, yaml, json, boto3
import os.path
from botocore.exceptions import ClientError

TEMPLATE_FILE = './templates/kubernetes-cluster.template'
WARDROOM_SPEC = './wardroom.json'

# Python's YAML library tries to interpret things like !Ref and the like as
# python classes, so just make that a no-op.
def default_ctor(loader, tag_suffix, node):
    return tag_suffix + ' ' + ''.join(str(e) for e in node.value)
yaml.add_multi_constructor('', default_ctor)

def load_spec():
    with open(WARDROOM_SPEC) as f:
        body = json.load(f)
        return body['ami']

def recordError(err):
    print("Error: {}".format(err), file=sys.stderr)

def read_ami_file():
    amis_by_region = {}
    # Open the template containing the AMI region map, read each AMI from
    # into amis_by_region
    with open(TEMPLATE_FILE, 'r') as stream:
        doc = yaml.load(stream)
        # eg: { "us-west-1": ... }
        for region, archmap in doc["Mappings"]["RegionMap"].items():
            # eg: { "64": "ami-1234abcd" }
            for arch, ami in archmap.items():
                amis_by_region[region] = ami
    return amis_by_region

def get_image(region, ami):
    conn = boto3.resource('ec2', region_name=region)
    return conn.Image(ami)

def check_public(img, region):
    if not img.public:
        recordError(
            "Region {}: AMI {} is not marked as public".format(region, ami)
        )
        return False
    return True

def check_tags(expected_tags, img, region):
    if img.description is None:
        recordError("Region {}: AMI {} has no description".format(region, img.id))
        return False
    # key1=val1 key2=val2 ...
    tags = dict(kv.split('=') for kv in img.description.split())
    for (key, expected) in expected_tags.items():
            val = tags.get(key) 
            if val is None:
                recordError(
                    "Region {}: AMI {} is missing tag {}".format(
                        region,
                        img.id,
                        key
                    )
                )
                return False
            if val != expected:
                recordError(
                    "Region {}: AMI {} tag {} has value {}, not {}".format(
                        region,
                        img.id,
                        key,
                        val,
                        expected)
                )
                return False
    return True

def check_valid(spec, ami, region):
    try:
        img = get_image(region, ami)
        valid = check_public(img, region) and check_tags(spec, img, region)
        if valid:
            print("Region {}: AMI {} is valid".format(region, ami))
        return valid
    except ClientError as e:
        if e.response['Error']['Code'] == 'InvalidAMIID.NotFound':
            recordError("Region {}: AMI {} not found".format(region, ami))
        else:
            recordError("Region {}: {}".format(
                region,
                e.response['Error']['Message']
            ))
        return False

if __name__ == '__main__':
    spec = load_spec()
    amis = read_ami_file()
    successes = sum(check_valid(spec, ami, region)
                    for (region, ami) in amis.items())
    errors = len(amis) - successes
    if errors == 0:
        print("Success: 0 errors found")
    else:
        print("{} errors found".format(errors), file=sys.stderr)
        exit(1)
