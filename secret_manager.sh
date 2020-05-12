#!/bin/bash
PREFIX="k3/uat/"
function AWS_SM_CREATE {
    aws --region ap-southeast-2 --profile kogan-nonprod secretsmanager \
        create-secret \
        --name "${PREFIX}${1}" \
        --secret-string "$2" || true
}
AWS_SM_CREATE "K3_TEST_PASSWORD" "mustbelongerthaneight"