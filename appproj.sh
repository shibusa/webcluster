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

# Install pip and additional tools
if [[ -z $(pip --version) ]]; then
  echo -e "${GREEN}Installing pip${NC}"
  sudo yum install python-setuptools python-pip python-wheel python-devel pcre-devel -y
  sudo pip install --upgrade pip
  mkdir .pip
  if [ ! -f $syshome/.pip/pip.conf ]; then
    echo -e "[list]\nformat=columns"| sudo tee -a $syshome/.pip/pip.conf
  fi
  # Install virtualenv and uwsgi
  sudo pip install virtualenv virtualenvwrapper uwsgi
fi

# run as vagrant user
sudo su - vagrant << NEWSHELL

# create virtualenv if it doesnt exist
if [ ! -d $syshome/${projectname}env ]; then
  echo -e "${GREEN}Creating virtualenv${NC}"
  virtualenv ${projectname}env
fi

# webapp doesn't exist
if [ ! -d $syshome/$projectname ]; then
  mkdir $projectname
  cd $projectname
  git init
  git remote add -f origin $github
  git config core.sparseCheckout true
  # project.ini, main project folder, manage.py, pip dependency will always be part of deploy
  echo -e "$projectname.ini\n/$projectname/\nmanage.py\nrequirements.txt" >> .git/info/sparse-checkout
  # additional files/folders to be pulled
  echo -e "/githubquery/\n/loginadmin/\n">> .git/info/sparse-checkout
  echo -e "${GREEN}Pulling webapp${NC}"
  git pull origin master
  cd ../
else
  cd $projectname
  echo -e "${GREEN}Updating webapp${NC}"
  git pull origin master
  cd ../
fi

# install pip requirements and migrate tables/ensure pip requirements up to date
source ${projectname}env/bin/activate
pip install -r $projectname/requirements.txt
python $projectname/manage.py makemigrations
python $projectname/manage.py migrate
python $projectname/manage.py loaddata init.json
sudo sed -i -e 's|SESSION_COOKIE_SECURE = False|SESSION_COOKIE_SECURE = True|g' $projectname/$projectname/settings.py
sudo sed -i -e 's|CSRF_COOKIE_SECURE = False|CSRF_COOKIE_SECURE = True|g' $projectname/$projectname/settings.py
deactivate
NEWSHELL

# Make uwsgi folder
uwsgidir="/etc/uwsgi/sites"
if [ ! -d $uwsgidir ]; then
  echo -e "${GREEN}Making $uwsgidir${NC}"
  sudo mkdir -p $uwsgidir
fi

#  Move *.ini to uwsgi folder
if [ -f $uswgidir/$projectname.ini ]; then
  echo -e "${GREEN}$projectname.ini already exists$uwsgidir${NC}"
elif [ -d $uwsgidir ] && [ -f $syshome/$projectname/$projectname.ini ]; then
  sudo mv $syshome/$projectname/$projectname.ini $uwsgidir
fi

# systemd uwsgi file
if [ ! -f /etc/systemd/system/uwsgi.service ]; then
  echo -e "[Unit]\nDescription=uWSGI Emperor service\n\n[Service]\nExecStart=/usr/bin/uwsgi --emperor /etc/uwsgi/sites\nRestart=always\nKillSignal=SIGQUIT\nType=notify\nNotifyAccess=all\n\n[Install]\nWantedBy=multi-user.target" | sudo tee -a /etc/systemd/system/uwsgi.service
fi

sudo systemctl enable uwsgi
if [[ $(sudo systemctl status uwsgi | grep running | awk '{print $3}') == "(running)" ]]; then
  sudo systemctl restart uwsgi
elif [[ $(sudo systemctl status uwsgi | grep dead | awk '{print $3}') == "(dead)" ]]; then
  sudo systemctl start uwsgi
fi
