# pip install pillow
# pip install selenium
import sys
import os
import argparse
import boto3
from boto3.s3.transfer import S3Transfer
from boto3.dynamodb.conditions import Key, Attr
from botocore.exceptions import ClientError
import json

parser=argparse.ArgumentParser()
parser.add_argument("-d", "--directory",
    dest="directory",
    help="Directory to upload",
    required=True)

parser.add_argument("-c","--config",
    dest="config",
    help="Config file to access AWS resources",
    required=True)
args = parser.parse_args()

with open(args.config,'r') as config_file:
    config_data = json.load(config_file)
client = boto3.client('s3',
    aws_access_key_id=config_data['accessKey'], 
    aws_secret_access_key=config_data['secretAccessKey']
)
transfer = S3Transfer(client)

sv_args = {}
dir_files = {}
for filename in os.listdir(args.directory):
    raw_filename, ext = os.path.splitext(filename)
    if raw_filename not in sv_args: sv_args[raw_filename] = {}
    if raw_filename not in dir_files: dir_files[raw_filename] = {}
    if ext == ".json":
        dir_files[raw_filename]['args'] = filename
    else:
        dir_files[raw_filename]['img'] = filename
for raw_filename in dir_files:
    
    # filter for unmatched files
    if not dir_files[raw_filename]['args'] and dir_files[raw_filename]['img']:
        print ("Warning: mismatched file with prefix'" + raw_filename + "' found in '" + args.directory + "'")
        continue

    # upload images or js to S3
    to_store = args.directory + '/' + dir_files[raw_filename]['img']
    key = config_data['projectName'] + '/' + dir_files[raw_filename]['img']
    transfer.upload_file(
            to_store,
            config_data['AWSBucketName'],
            key,
            extra_args={'ACL': 'public-read'})
    sv_args[raw_filename]['file_url'] = str('%s/%s/%s' % (client.meta.endpoint_url, config_data['AWSBucketName'], key))

    # upload entries for image use to DynamoDB
    json_args = json.load(open(args.directory + '/' + dir_files[raw_filename]['args'], 'r'))
    if "file_url" in sv_args[raw_filename]:
        json_args['inc_info'] = sv_args[raw_filename]['file_url']
    sv_args[raw_filename] = json_args

dynamodb = boto3.resource('dynamodb',
    aws_access_key_id=config_data['accessKey'], 
    aws_secret_access_key=config_data['secretAccessKey']
)
imgs_table = dynamodb.Table(config_data['dynamoImagesTable'])
with imgs_table.batch_writer() as batch:
    for key in sv_args:
        sv_args[key]['identifier'] = sv_args[key]['inc_info']

        batch.put_item(
            Item = sv_args[key]
        )

