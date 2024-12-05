apt install mysql-server -y
apt update -y
apt install -y mysql-server
sed -i "s/^bind-address\s*=.*/bind-address = 192.168.30.42/" /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql

 mysql <<EOF
CREATE DATABASE db_wordpress;
CREATE USER 'david'@'192.168.30.%' IDENTIFIED BY 'S1234';
GRANT ALL PRIVILEGES ON db_wordpress.* TO 'david'@'192.168.30.%';
FLUSH PRIVILEGES;
EOF