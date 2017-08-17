#!/bin/bash

PASSENGER_VERSION_STRING=$(passenger-config about version)
# Phusion Passenger 5.1.2

PASSENGER_VERSION=$(echo $PASSENGER_VERSION_STRING | cut -d ' ' -f 3)
# 5.1.2
# echo $PASSENGER_VERSION

RUBY_VERSION_STRING=$(ruby -v)
# ruby 2.3.3p222 (2016-11-21 revision 56859) [x86_64-linux]

RUBY_VERSION=$(echo $RUBY_VERSION_STRING | cut -d ' ' -f 2 | cut -d 'p' -f 1)
# 2.3.3
# echo $RUBY_VERSION

RUBY_BRANCH_VERSION="$(echo $RUBY_VERSION | cut -d '.' -f 1).$(echo $RUBY_VERSION | cut -d '.' -f 2).0"
# 2.3.0
# echo $RUBY_BRANCH_VERSION

sed -i -e "s/RUBY_VERSION/${RUBY_VERSION}/g" ${NGINX_PATH}/conf/passenger.conf
sed -i -e "s/RUBY_BRANCH_VERSION/${RUBY_BRANCH_VERSION}/g" ${NGINX_PATH}/conf/passenger.conf
sed -i -e "s/PASSENGER_VERSION/${PASSENGER_VERSION}/g" ${NGINX_PATH}/conf/passenger.conf
