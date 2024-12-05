apt update -y
apt install -y apache2
a2enmod proxy
a2enmod proxy_http
a2enmod proxy_balancer
a2enmod lbmethod_byrequests
cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/load-balancer.conf
sed -i '/DocumentRoot \/var\/www\/html/s/^/#/' /etc/apache2/sites-available/load-balancer.conf
sed -i '/:warn/ a \<Proxy balancer://mycluster>\n    # Server 1\n    BalancerMember http://192.168.30.20\n    # Server 2\n    BalancerMember http://192.168.30.30\n</Proxy>\n#todas las peticiones las envía al siguiente balanceador\nProxyPass / balancer://mycluster/' /etc/apache2/sites-available/load-balancer.conf
a2ensite load-balancer.conf
a2dissite 000-default.conf
systemctl restart apache2
systemctl reload apache2