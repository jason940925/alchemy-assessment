import boto3
import logging
import sys

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def main(clusterName, region):
    logger.info(clusterName)
    lbList = []
    client = boto3.client('resourcegroupstaggingapi',region_name=region)
    response = client.get_resources(
        TagFilters=[
            {
                'Key': 'kubernetes.io/cluster/'+clusterName,
                'Values': [
                    'owned',
                ]
            },
        ],
        ResourceTypeFilters=[
            'elasticloadbalancing:'
        ]
    )
    for x in response["ResourceTagMappingList"]:
        resourceArn = x["ResourceARN"]
        targetString = "loadbalancer/"
        start = resourceArn.find(targetString) + len(targetString)
        lbList.append(resourceArn[start:])
        delete_loadbalancer(resourceArn[start:], region)
        
    logger.info("List of deleted lb: %s" , lbList)

def delete_loadbalancer(lb_name, region):
    elb = boto3.client('elb',region_name=region)
    response = elb.delete_load_balancer(
        LoadBalancerName=lb_name
    )
    logging.info("Deleted loadbalancer: %s",lb_name)
    logging.info("Deleted loadbalancer result: %s",response)

if __name__ == "__main__":
   main(sys.argv[1], sys.argv[2])
