#!/usr/bin/env bash
yum install https://download.postgresql.org/pub/repos/yum/9.6/redhat/rhel-7-x86_64/pgdg-centos96-9.6-3.noarch.rpm -y
yum install postgresql96 postgresql96-server -y

/usr/pgsql-9.6/bin/postgresql96-setup initdb
# Allowed Auth
sudo sed -i -e 's|host    all             all             127.0.0.1/32            ident|host    all             all             0.0.0.0/0            trust|g' /var/lib/pgsql/9.6/data/pg_hba.conf
# Listen Address; need to fix secondary sed statement so config notes dont get overwritten
sudo sed -i -e 's|#listen_addresses|listen_addresses|g' /var/lib/pgsql/9.6/data/postgresql.conf
sudo sed -i -e 's|localhost|*|g' /var/lib/pgsql/9.6/data/postgresql.conf

# Start service at boot and start service now
systemctl enable postgresql-9.6
if [[ $(sudo systemctl status postgresql-9.6 | grep dead | awk '{print $3}') == "(dead)" ]]; then
  sudo systemctl start postgresql-9.6
fi

echo "PostgreSQL Install Complete"
