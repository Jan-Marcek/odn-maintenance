#!/bin/bash 
set -e
VIRTUOSO_CONFIG=/etc/default/virtuoso-opensource-7
apt-get update

# install virtuoso
export DEBIAN_FRONTEND=noninteractive
apt-get -q -y install virtuoso-opensource=7.2

# configure virtuoso
sed --in-place \
        -e "s/\RUN.*/RUN=yes/" \
         $VIRTUOSO_CONFIG

service virtuoso-opensource-7 restart
apt-get -q -y install odn-simple