apt update -y
apt install apache2 -y
apt install nfs-common -y
apt install php libapache2-mod-php php-mysql php-curl php-gd php-xml php-mbstring php-xmlrpc php-zip php-soap php -y
a2enmod rewrite
#servidores web
sudo sed -i 's|DocumentRoot .*|DocumentRoot /nfs/shared/wordpress|g' /etc/apache2/sites-available/000-default.conf

sed -i '/<\/VirtualHost>/i \
<Directory /nfs/shared/wordpress>\
    Options Indexes FollowSymLinks\
    AllowOverride All\
    Require all granted\
</Directory>' /etc/apache2/sites-available/000-default.conf


cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/websv.conf
# Montar la carpeta compartida desde el servidor NFS

mkdir -p /nfs/shared
mount 192.168.30.28:/var/nfs/shared /nfs/shared
a2dissite 000-default.conf
a2ensite websv.conf
echo "192.168.30.28:/var/nfs/general /nfs/general nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0" | sudo tee -a /etc/fstab
mount -a 
systemctl restart apache2
systemctl reload apache2
systemctl status apache2