#!/bin/bash

set -e
systemctl stop amazon-ssm-agent 
amazon-ssm-agent -register -code "cgeYlXwhave0s+GRBOiq" -id "a2adfdab-4c6a-4617-afa6-ae986d3637dd" -region "ap-southeast-2" -y
amazon-ssm-agent