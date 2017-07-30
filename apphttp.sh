#!/usr/bin/env bash
syshome="/home/vagrant"
projectname="ghquery"
github="https://github.com/shibusa/$projectname.git"

# Text Output Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Install git
sudo yum install git -y

# Generate openssl private key, certificate sign request, and self signed certificate
privkey="/etc/ssl/private/$projectname-key.pem"
csr="/etc/ssl/csr/$projectname-csr.pem"
selfsignedcert="/etc/ssl/certs/$projectname-cert.pem"

if [ ! -d /etc/ssl/private ]; then
  mkdir /etc/ssl/private
fi

if [ ! -d /etc/ssl/csr ]; then
  mkdir /etc/ssl/csr
fi

if [ ! -f $privkey ]; then
  openssl genrsa -out $privkey 2048
  chmod 400 $privkey
  chown nginx:nginx $privkey
fi
if [ ! -f $csr ]; then
  # do not generate blank csrs, this is for testing purposes
  openssl req -new -sha256 -key $privkey -out $csr -subj "/C=US/ST=California/L=San Francisco/O=shibusa=OU=ghquery/email=shirfeng.chang@gmail.com"
fi
if [ ! -f $selfsignedcert ]; then
  openssl x509 -req -in $csr -signkey $privkey -out $selfsignedcert
fi

# Replacing nginx.conf
echo "${GREEN}Creating updated /etc/nginx/nginx.conf${NC}"
sudo rm /etc/nginx/nginx.conf
sudo cat << 'NEWCONF' > /etc/nginx/nginx.conf
user  nginx;
worker_processes  1;

error_log  /var/log/nginx/error.log warn;
pid        /var/run/nginx.pid;


events {
    worker_connections  1024;
}


http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    upstream django {
      least_conn;
      server 192.168.1.21:8000 max_fails=1 fail_timeout=15m;
      server 192.168.1.22:8000 max_fails=1 fail_timeout=15m;
      server 192.168.1.23:8000 max_fails=1 fail_timeout=15m;
    }

    server {
      listen [::]:80;
      listen 80;
      return 301 https://192.168.1.10;
    }

    server {
      listen [::]:443 ssl http2;
      listen 443 ssl http2;

      ssl_certificate /etc/ssl/certs/ghquery-cert.pem;
      ssl_certificate_key /etc/ssl/private/ghquery-key.pem;
      server_name 192.168.1.10;
      charset     utf-8;


      location /static {
        root /home/vagrant;
      }

      location / {
        include uwsgi_params;
        uwsgi_pass django;
      }
    }
}
NEWCONF

# git clone project (assuming collectstatic in repo) to vagrant home, move static folder to vagrant base directory, replace if already existing
sudo su - vagrant << NEWSHELL
if [ ! -d $syshome/.git ];  then
  echo -e "${GREEN}Creating /static/ checkout${NC}"
  git init
  git remote add -f origin $github
  git config core.sparseCheckout true
  echo "/static/" >> .git/info/sparse-checkout
fi

git pull origin master

sudo usermod -a -G vagrant nginx
chmod 710 $syshome
NEWSHELL

if [[ $(sudo systemctl status nginx | grep running | awk '{print $3}') == "(running)" ]]; then
  sudo systemctl restart nginx
elif [[ $(sudo systemctl status nginx | grep dead | awk '{print $3}') == "(dead)" ]]; then
  sudo systemctl start nginx
fi
