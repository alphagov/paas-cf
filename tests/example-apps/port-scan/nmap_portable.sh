#!/bin/bash

mkdir -p portable/debs
cd portable/debs
apt-get download nmap liblua5.2 liblinear1 libblas3
cd ..
for file in debs/*.deb
    do
        ar x "$file" && tar xf data.tar.* && rm control.tar.* && rm data.tar.* && rm debian-binary
    done
cd ..
