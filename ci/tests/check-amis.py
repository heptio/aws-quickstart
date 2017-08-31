#!/usr/bin/env python

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

import sys, yaml, json, boto.ec2
from boto.ec2 import connect_to_region

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
    sys.stderr.write("Error: "+err+"\n")
    errs.append(err)

# Open the template containing the AMI region map, read each AMI from
# into amis_byregion
with open(tmplfile, 'r') as stream:
    doc = yaml.load(stream)
    # eg: { "us-west-1": ... }
    for region, archmap in doc["Mappings"]["RegionMap"].iteritems():
        # eg: { "64": "ami-1234abcd" }
        for arch, ami in archmap.iteritems():
            amis_byregion[region] = ami

for region, ami in amis_byregion.iteritems():
    try:
        # Ask EC2 about it
        conn = connect_to_region(region)
        imgs = conn.get_all_images(image_ids=[ami])

        # Make sure we got exactly one result
        if len(imgs) == 0:
            recordError("Region "+region+": AMI "+ami+" not found")
            continue
        elif len(imgs) > 1:
            recordError("Region "+region+": Multiple AMIs found with ID "+ami+"?")
            continue

        # Ensure it's public
        img = imgs[0]
        if img.is_public:
            print("Region "+region+": AMI "+ami+" exists and is public")
        else:
            recordError("Region "+region+": AMI "+ami+" is not marked as public")
    except boto.exception.EC2ResponseError as err:
        recordError("Region "+region+": "+err.message)

if len(errs) > 0:
    print str(len(errs)) + " errors found"
    exit(1)
else:
    print "Success: 0 errors found"
