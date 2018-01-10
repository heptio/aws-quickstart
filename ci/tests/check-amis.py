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
from botocore.exceptions import ClientError

tmplfile = './templates/kubernetes-cluster.template'

# Python's YAML library tries to interpret things like !Ref and the like as
# python classes, so just make that a no-op.
def default_ctor(loader, tag_suffix, node):
    return tag_suffix + ' ' + ''.join(str(e) for e in node.value)
yaml.add_multi_constructor('', default_ctor)

# Keep track of the AMI's and the errors for them
amis_byregion = {}
errs = []


def recordError(err):
    print("Error: {}".format(err), file=sys.stderr)
    errs.append(err)

# Open the template containing the AMI region map, read each AMI from
# into amis_byregion
with open(tmplfile, 'r') as stream:
    doc = yaml.load(stream)
    # eg: { "us-west-1": ... }
    for region, archmap in doc["Mappings"]["RegionMap"].items():
        # eg: { "64": "ami-1234abcd" }
        for arch, ami in archmap.items():
            amis_byregion[region] = ami

for region, ami in amis_byregion.items():
    try:
        # Ask EC2 about it
        conn = boto3.resource('ec2', region_name=region)
        img = conn.Image(ami)

        # Ensure it's public
        if img.public:
            print("Region {}: AMI {} exists and is public".format(region, ami))
        else:
            recordError("Region {}: AMI {} is not marked as public".format(region, ami))
    except ClientError as e:
        if e.response['Error']['Code'] == 'InvalidAMIID.NotFound':
            recordError("Region {}: AMI {} not found".format(region, ami))
        else:
            recordError("Region {}: {}".format(region, e.response['Error']['Message']))

if len(errs) > 0:
    print("{} errors found".format(len(errs)), file=sys.stderr)
    exit(1)
else:
    print("Success: 0 errors found")
