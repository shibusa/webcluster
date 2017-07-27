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

    include /etc/nginx/conf.d/*.conf;

    upstream django {
      least_conn;
      server 192.168.1.21:8000;
      server 192.168.1.22:8000;
      server 192.168.1.23:8000;
    }

    server {
        listen 80;
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
git clone $github
if [ -d $syshome/$projectname/static ];  then
  rsync -a $syshome/$projectname/static $syshome
else
  mv $syshome/$projectname/static $syshome
fi
rm -rf $projectname

sudo usermod -a -G vagrant nginx
chmod 710 $syshome
NEWSHELL

if [[ $(sudo systemctl status nginx | grep running | awk '{print $3}') == "(running)" ]]; then
  sudo systemctl restart nginx
elif [[ $(sudo systemctl status nginx | grep dead | awk '{print $3}') == "(dead)" ]]; then
  sudo systemctl start nginx
fi
