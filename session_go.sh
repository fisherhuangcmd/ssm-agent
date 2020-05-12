#! /bin/bash
set -e
function usage_error() {
  echo Usage: $0 ECS_CLUSTER_ARN TASK_DEF_ARN
  exit 1
}

function start_ecs_task() {
   aws ecs run-task --launch-type FARGATE \
   --cluster=$ECS_CLUSTER_ARN \
   --task-definition=${TASK_DEF_ARN:-kxe-bastion} \
   --network-configuration='{"awsvpcConfiguration":{"subnets":["subnet-007470f390d07db15","subnet-0dac7bee6638828c6"],"securityGroups":["sg-0f86772efc3ced502"],"assignPublicIp":"ENABLED"}}'
}
function ssm_activation() {
    echo 'Token expire, request activation code'
    result=$(aws ssm create-activation --default-instance-name ${INSTANCE_NAME:-KXEBastionContainers} --iam-role kxe-session-manager-role --registration-limit 100 --region ap-southeast-2 --tags "Key=App,Value=KxeBastion")
    activation_code=$(jq -r .ActivationCode <<< $result)
    activation_id=$(jq -r .ActivationId <<< $result)

    aws ssm put-parameter --name /kxe/ksub/bastion/activation_code \
    --value $activation_code \
    --type SecureString \
    --overwrite
    aws ssm put-parameter --name /kxe/ksub/bastion/activation_id \
    --value $activation_id \
    --type SecureString \
    --overwrite
}
export ECS_CLUSTER_ARN=$1; echo "ECS_CLUSTER_ARN= $ECS_CLUSTER_ARN"
export TASK_DEF_ARN=$2; echo "TASK_DEF_ARN = ${TASK_DEF_ARN:-kxe-bastion}"
export INSTANCE_NAME=$3; echo "INSTANCE_NAME = ${INSTANCE_NAME:-KXEBastionContainers}"
[[ -n "$ECS_CLUSTER_ARN" ]] || usage_error
code=15
wait_period=0


is_activated=$(aws ssm describe-activations | jq '.ActivationList[] | select((.Expired==false) and .IamRole=="kxe-session-manager-role")')

if [ -z "${is_activated}" ]; then
   ssm_activation || echo "Existing activated session in used"
   echo 'ecs task'
   start_ecs_task

fi
activation_id=$(aws ssm get-parameter --name /kxe/ksub/bastion/activation_id --with-decryption | jq .Parameter.Value)
status=$(aws ssm describe-instance-information | jq '.InstanceInformationList[] |  ((.PingStatus=="Online") and .ActivationId=="314c3464-c95c-4390-b595-4a5969c57758")')
   if [ ! -z "$status" ];then
      instance_id=$(jq -r .InstanceId <<< $status)
      echo "Establishing session to: $instance_id"
      aws ssm start-session --target $instance_id
   else
      echo 'unable to connect'
   fi
#       break
# while true;
# do
#    else
#       wait_period=$(($wait_period+10)) #this is your running time
#       if [ $wait_period -gt 300 ];then
#             echo "No avaliable instance online 5 minutes, please try again now.."
#             break
#       else
#          printf "|\e[48;5;${code}m%${per%.*}s\e[31m${per%.*}"
#       fi
#    fi
# done

