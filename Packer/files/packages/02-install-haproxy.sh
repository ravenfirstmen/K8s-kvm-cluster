#!/bin/bash

set -e -v

sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get install haproxy  -y

sudo systemctl disable haproxy.service
