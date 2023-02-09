#!/bin/bash

# PostgreSQL v15 Installation
# =============================

# Discover OS Version
FILENAME=/etc/os-release
version=`grep -e ^VERSION_ID= ${FILENAME}`
version=${version#*\"}
version=${version%*\"}
version=${version%*\.*}


if [[ "$version" == "7" ]]
then

  # CENTOS/RHEL 7
  yum -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm
  yum -y install https://download-ib01.fedoraproject.org/pub/epel/7/x86_64/Packages/l/libzstd-1.5.2-1.el7.x86_64.rpm
  yum -y update
  yum -y install postgresql15-server postgresql15-contrib yum-plugin-versionlock

  # Lock package version
  yum versionlock postgresql15*

elif [[ "$version" == "8" ]]
then

  # CENTOS/RHEL 8
  dnf -y install https://download.postgresql.org/pub/repos/yum/reporpms/EL-8-x86_64/pgdg-redhat-repo-latest.noarch.rpm
  dnf -y install https://download-ib01.fedoraproject.org/pub/epel/7/x86_64/Packages/l/libzstd-1.5.2-1.el7.x86_64.rpm
  dnf -qy module disable postgresql
  dnf -y install postgresql15-server postgresql15-contrib python3-dnf-plugin-versionlock

  # Lock package version
  dnf versionlock postgresql15*

fi

# Initialize database

/usr/pgsql-15/bin/postgresql-15-setup initdb


# Change "max_connections" parameter to 200
sed -i -e 's/max_connections = 100/max_connections = 200/g' /var/lib/pgsql/15/data/postgresql.conf

# Start PostgreSQL and enable auto-start
systemctl start postgresql-15
systemctl enable postgresql-15

# Define password for users 'postgresql' and 'vbuser'

psqlpassword='Pa$$w0rd'
vbuserpassword='Pa$$w0rd'


# Update password for postgresql user
su - postgres -c "psql -c \"alter user postgres with password '\"'${psqlpassword}'\"'\""


# Create user vbuser and set the password
su - postgres -c "psql -c \"CREATE USER vbuser WITH ENCRYPTED PASSWORD '\"'${vbuserpassword}'\"'\""
su - postgres -c "psql -c \"ALTER USER vbuser CREATEDB\""


# Enable remote connections to PostgreSQL
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/g" /var/lib/pgsql/15/data/postgresql.conf
sed -i "s/127.0.0.1\/32            /0.0.0.0\/0 /g" /var/lib/pgsql/15/data/pg_hba.conf
systemctl restart postgresql-15


# Add rule to local firewall
firewall-cmd --zone=public --permanent --add-port 5432/tcp
systemctl restart firewalld.service
