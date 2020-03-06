#!/bin/bash
set -e 

RUN_TYPE=$1
NODE_TYPE=$2

if [[ "$RUN_TYPE" == "deploy" ]] && [[ "$NODE_TYPE" == "minio" ]];then
    # Starting the Installation for Worker Nodes
    cd ${PWD}/TerraformTemplates/K8s-Minion
    aws s3 cp s3://terraformstatek8s/minion/terraform.tfstate terraform.tfstate 2> /dev/null || echo "No terraform.tfstate file present in S3 Bucket" 
    terraform init
    terraform apply -auto-approve
    # echo -e "[worker]\n" >> ../../inventory
    # touch {PWD}/TerraformTemplates/K8s-Master/hosts_minion
    terraform output | awk -F '=' '{print $2}' | awk -F ':' '{print $2}'| tr -s ',' '\n' | tr -s '[' '\b' | tr -s ']' '\b' > hosts_minion
    # cp hosts_minion ../K8s-Master/
    # echo  " " >> ../../hosts_minion
    aws s3 cp hosts_minion s3://terraformstatek8s/
    aws s3 cp terraform.tfstate s3://terraformstatek8s/minion/

elif [[ "$RUN_TYPE" == "deploy" ]] && [[ "$NODE_TYPE" == "master" ]];then
    # Starting Installion for Kubernetes Master Node
    # cd ../K8s-Master
    cd ${PWD}/TerraformTemplates/K8s-Master
    aws s3 cp s3://terraformstatek8s/master/terraform.tfstate terraform.tfstate 2> /dev/null || echo "No terraform.tfstate file present in S3 Bucket"
    aws s3 cp s3://terraformstatek8s/hosts_minion hosts_minion 2> /dev/null || echo "No hosts_minion file present in S3 Bucket"
    terraform init
    terraform apply -auto-approve
    aws s3 cp terraform.tfstate s3://terraformstatek8s/master/

elif [[ "$RUN_TYPE" == "destroy" ]];then
    # Destroying Master Resources
    cd ${PWD}/TerraformTemplates/K8s-Master
    terraform init
    aws s3 cp s3://terraformstatek8s/master/terraform.tfstate terraform.tfstate 2> /dev/null || echo "No terraform.tfstate file present in S3 Bucket"
    terraform destroy -auto-approve
    aws s3 cp terraform.tfstate s3://terraformstatek8s/master/

    # Destroying the Worker Nodes
    cd ../K8s-Minion
    terraform init
    aws s3 cp s3://terraformstatek8s/minion/terraform.tfstate terraform.tfstate 2> /dev/null || echo "No terraform.tfstate file present in S3 Bucket" 
    terraform destroy -auto-approve
    aws s3 cp terraform.tfstate s3://terraformstatek8s/minion/

elif [[ "$RUN_TYPE" == "validate" ]];then
    # Validating Master Resources
    cd ${PWD}/TerraformTemplates/K8s-Master
    terraform init
    terraform validate

    # Validating the Worker Nodes
    cd ../K8s-Minion
    terraform init
    terraform validate

# elif [[ "$RUN_TYPE" == "delete_state_file" ]];then
#     # Validating Master Resources
#     cd ${PWD}/TerraformTemplates/K8s-Master
#     terraform

#     # Validating the Worker Nodes
#     cd ../K8s-Minion
#     terraform init
#     terraform validate

else
    echo "Please Enter one Argument"
    echo "Usage: run.sh [deploy|destroy]"
    exit 1
fi





# terraform output | awk -F '=' '{print $2}' | awk -F ':' '{print $2}' | tr -s ',' '\n' | tr -s '[' ' ' | tr -s ']' ' ' >> ../../inventory
