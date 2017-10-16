#!/bin/bash

tar czf web-security.tar.gz index.js build lib sql test package.json yarn.lock
scp web-security.tar.gz web-security@ubuntu-vm:~
rm web-security.tar.gz

ssh web-security@ubuntu-vm <<'ENDSSH'
pm2 stop web-security
rm -rf web-security
mkdir web-security
tar xf web-security.tar.gz -C web-security
rm web-security.tar.gz
cd web-security 
yarn install
pm2 start web-security 
ENDSSH