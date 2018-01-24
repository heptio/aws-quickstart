import urllib.request as request
import cfn_tools
import yaml

# update-bastion-amis.py is a helper script to get the newer amis from the quickstart-linux-bastion upstream.

AMI_TYPE='US1604HVM'
QUICKSTART_LINUX_BASTION_CF_TEMPLATE = 'https://raw.githubusercontent.com/aws-quickstart/quickstart-linux-bastion/master/templates/linux-bastion.template'


def main():
    print(yaml.dump(get_actual_amis(), Dumper=cfn_tools.CfnYamlDumper, default_flow_style = False))

def get_actual_amis():
    resp = request.urlopen(QUICKSTART_LINUX_BASTION_CF_TEMPLATE)
    cf = yaml.load(resp.read())

    mappings = cf['Mappings']['AWSAMIRegionMap']
    clean_mappings = {}
    for key, value in mappings.items():
        if key == 'AMI':
            continue
        for ami_type, ami_number in value.items():
            if ami_type == AMI_TYPE:
                # this is our formatting
                clean_mappings[key] = {
                    '64': ami_number
                }
    return {'Mappings': {'RegionMap': clean_mappings}}

if __name__ == "__main__":
    main()
