import argparse
import boto3
import sys

def get_regions():
    regions = ['us-west-1','us-west-2','us-east-1','us-east-2','ap-northeast-1','ap-northeast-2','ap-northeast-3','ap-south-1','ap-southeast-1','ap-southeast-2','ca-central-1','eu-central-1','eu-north-1','eu-west-1','eu-west-2','eu-west-3']

    ec2_client = boto3.client('ec2', region_name='us-east-1')
    try:
        response = ec2_client.describe_regions()
        return [region['RegionName'] for region in response['Regions']]
    except RuntimeError as e:
        print("Warning: Can't describe_regions. Falling back to default list. The error was {e}")
        return regions

def find_best_spot_price(instance_type, product_description):
    best_price = float('inf')
    best_az = ''

    for region in get_regions():
        ec2_client = boto3.client('ec2', region_name=region)
        response = ec2_client.describe_spot_price_history(
            InstanceTypes=[instance_type],
            ProductDescriptions=[product_description],
            MaxResults=19
        )

        if response['SpotPriceHistory']:
            for spot_price in response['SpotPriceHistory']:
                if float(spot_price['SpotPrice']) < best_price:
                    best_price = float(spot_price['SpotPrice'])
                    best_az = spot_price['AvailabilityZone']

    return best_az, best_price

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
                    prog='find_best_spot_price.py',
                    description='find the AWS region wit the best ECE spot price',
                    epilog='So long and thanks for all the fish')
    parser.add_argument('-i', '--instance_type', required=True)
    args = parser.parse_args()
    instance_type = args.instance_type
    product_description = 'Linux/UNIX'

    best_az, best_price = find_best_spot_price(instance_type, product_description)

    if best_az:
        print(f"Best AZ is {best_az} with a price of {best_price}")
    else:
        print("No results found. Check parameters.")
        sys.exit(1)
