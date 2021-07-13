#!/usr/bin/env bash

set -euo pipefail

BUCKET="my-super-backup-bucket"
REGION="eu-central-1"
IAM_USER="my-super-backup-bucket"

aws s3api create-bucket \
    --bucket $BUCKET \
    --region $REGION \
    --create-bucket-configuration LocationConstraint=$REGION

aws s3api put-bucket-encryption \
    --bucket $BUCKET \
    --server-side-encryption-configuration '{"Rules": [{"ApplyServerSideEncryptionByDefault": {"SSEAlgorithm": "AES256"}}]}'

aws iam create-user --user-name $IAM_USER

cat >aws-s3-uploads-policy.json<<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:List*",
                "s3:Put*"
            ],
            "Resource": "*"
        }
    ]
}
EOF

arn=$(aws iam create-policy --policy-name $BUCKET --policy-document file://aws-s3-uploads-policy.json | jq -r '.Policy.Arn')

# Get Arn from the returned json or just replace account ID

aws iam attach-user-policy --policy-arn "$arn" --user-name $IAM_USER

aws iam create-access-key --user-name $IAM_USER

