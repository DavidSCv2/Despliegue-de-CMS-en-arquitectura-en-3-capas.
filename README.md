# Despliegue-de-CMS-en-arquitectura-en-3-capas.
 CMS Wordpress en alta disponibilidad y escalable en AWS. 
## Descripción General

Este proyecto detalla el despliegue de un sitio WordPress en AWS utilizando una arquitectura de tres capas. La infraestructura asegura alta disponibilidad y escalabilidad siguiendo los principios de seguridad y segmentación de red. A continuación, se describen los detalles técnicos y los scripts de aprovisionamiento utilizados.

## Requisitos

- Acceso a AWS: Una cuenta de AWS activa.
- CLI de AWS: Configurada con las credenciales adecuadas.
- Dominio público: Registrado y apuntando a una IP elástica.
- Permisos: Acceso SSH a las instancias EC2.
  
**Dependencias:**

- Linux (Ubuntu 20.04 o similar) en las instancias EC2.
- Apache, PHP, NFS y MySQL/MariaDB.

## Estructura del Proyecto
├── balanceador.sh      # Script para configurar el balanceador de carga.

├── nfs.sh              # Script para configurar el servidor NFS y el contenido de WordPress.

├── webservers.sh       # Script para configurar los servidores backend.

├── sgbd.sh              # Script para configurar la base de datos.

└── README.md           # Documento técnico y explicativo.


 ## Arquitectura de Red en AWS

  ### Capa 1: Balanceador de Carga (Pública)

- Instancia EC2 con Apache configurado como balanceador de carga.
- Solo permite acceso desde el exterior por los puertos 80 (HTTP) y 443 (HTTPS).

### Capa 2: Servidores Backend + NFS (Privada)
- Dos instancias EC2 configuradas como servidores web que se conectan a un servidor NFS.
- Servidor NFS compartiendo los archivos de WordPress.

### Capa 3: Base de Datos (Privada)
- Instancia EC2 con MySQL/MariaDB configurada para la base de datos de WordPress.
- Solo permite conexiones desde los servidores backend.

## Scripts de aprovisionamiento

Los scripts de aprovisionamiento configuran el software y las configuraciones necesarias para cada instancia.

### 1. Balanceador de Carga (balanceador.sh)
Configura Apache como balanceador de carga con módulos proxy.
![balanceador sh 1](https://github.com/user-attachments/assets/92ee8d15-f6f9-4204-b26d-5f693211bc6e)

#### Actualización del sistema y instalación de Apache:

```console
apt update -y
apt install -y apache2
```
- Actualiza la lista de paquetes e instala Apache.

#### Habilitación de módulos de Apache:

```console
a2enmod proxy
a2enmod proxy_http
a2enmod proxy_balancer
a2enmod lbmethod_byrequests
```
- Activa los módulos necesarios para el balanceo de carga:
 - `proxy`: Permite que Apache actúe como un proxy inverso.
 - `proxy_http`: Habilita el soporte para proxys sobre HTTP.
 - `proxy_balancer`: Permite definir clústeres de servidores para balanceo.
 - `lbmethod_byrequests`: Distribuye las solicitudes en función del número de peticiones por servidor.

#### Configuración del balanceador:

- Se copia el archivo de configuración predeterminado:
```console
cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/load-balancer.conf
```

- Se comenta la línea del `DocumentRoot`:
```console
sed -i '/DocumentRoot \/var\/www\/html/s/^/#/' /etc/apache2/sites-available/load-balancer.conf
```

#### Definición del clúster de balanceo:

-Se agrega la configuración del clúster de servidores al archivo `load-balancer.conf`:

```console
sed -i '/:warn/ a \<Proxy balancer://mycluster>\n    # Server 1\n    BalancerMember http://192.168.30.20\n    # Server 2\n    BalancerMember http://192.168.30.30\n</Proxy>\n#todas las peticiones las envía al siguiente balanceador\nProxyPass / balancer://mycluster/' /etc/apache2/sites-available/load-balancer.conf
```

- Define un clúster llamado `mycluster` con dos servidores (`192.168.30.20` y `192.168.30.30`).
- Redirige todas las peticiones al clúster mediante `ProxyPass`.

#### Habilitación de la configuración y reinicio del servicio:
```console
a2ensite load-balancer.conf
a2dissite 000-default.conf
systemctl restart apache2
systemctl reload apache2
```



### 2. Servidor NFS (nfs.sh)
Configura NFS para compartir el contenido de WordPress.
![nfs sh 1](https://github.com/user-attachments/assets/1b116d0c-83c7-445c-9287-2b40bbd63de0)

#### Actualización del sistema y instalación de Apache:

```console
apt update -y
apt install nfs-kernel-server -y
apt install unzip -y
apt install curl -y
apt install php php-mysql -y
apt install mysql-client -y
```
- **nfs-kernel-server**: Instala el servidor NFS.
- **unzip y curl**: Utilizados para descargar y extraer WordPress.
- **php y php-mysql**: Proporcionan soporte para ejecutar WordPress.
- **mysql-client**: Permite conectarse a una base de datos remota.

#### Creación y configuración del directorio compartido:
```console
mkdir /var/nfs/shared -p
chown -R nobody:nogroup /var/nfs/shared
```

- Crea el directorio `/var/nfs/shared` y lo asigna al usuario/grupo nobody:nogroup, que es una práctica común para recursos compartidos.

#### Exportación del directorio NFS:
 ```console
 sed -i '$a /var/nfs/shared    192.168.30.20(rw,sync,no_subtree_check)' /etc/exports
 sed -i '$a /var/nfs/shared    192.168.30.30(rw,sync,no_subtree_check)' /etc/exports
```
- Añade entradas al archivo `/etc/exports` para permitir que los servidores `192.168.30.20` y `192.168.30.30` accedan al directorio con permisos de lectura/escritura (`rw`).
- **sync**: Asegura que los cambios se escriben en el disco antes de responder al cliente.
- **no_subtree_check**: Mejora el rendimiento y evita problemas con ciertos tipos de configuraciones.

#### Descarga y configuración de WordPress:
```console
curl -O https://wordpress.org/latest.zip
unzip -o latest.zip -d /var/nfs/shared/
chmod 755 -R /var/nfs/shared/
chown -R www-data:www-data /var/nfs/shared/*
```

- Descarga y descomprime WordPress en el directorio compartido.
- Cambia permisos y asigna el contenido a `www-data`, el usuario estándar de Apache para ejecutar sitios web.

#### Reinicio del servicio NFS:
```console
systemctl restart nfs-kernel-server
```

- Reinicia el servidor NFS para aplicar los cambios.

### 3. Webservers (webservers.sh)
![webservers sh1](https://github.com/user-attachments/assets/0cd06dff-ff3a-40ea-966a-4f2725c43da5)

#### Actualización e instalación de paquetes:
```console
apt update -y
apt install apache2 -y
apt install nfs-common -y
apt install php libapache2-mod-php php-mysql php-curl php-gd php-xml php-mbstring php-xmlrpc php-zip php-soap php -y
a2enmod rewrite
```

- **apache2**: Instala el servidor web.
- **nfs-common**: Permite a los servidores web acceder a recursos NFS.
- **php y módulos**: Instala PHP y extensiones necesarias para WordPress.
- **rewrite**: Habilita el módulo de reescritura de URLs en Apache.

#### Configuración de Apache:
```console
sudo sed -i 's|DocumentRoot .*|DocumentRoot /nfs/shared/wordpress|g' /etc/apache2/sites-available/000-default.conf
```

- Cambia el directorio raíz de Apache a `/nfs/shared/wordpress`, donde estará WordPress montado desde el servidor NFS.

#### Permisos de acceso:
```console
sed -i '/<\/VirtualHost>/i \
<Directory /nfs/shared/wordpress>\
    Options Indexes FollowSymLinks\
    AllowOverride All\
    Require all granted\
</Directory>' /etc/apache2/sites-available/000-default.conf
```

- Agrega una configuración para permitir el acceso y habilitar .htaccess en el directorio compartido.

#### Creación de una nueva configuración de sitio:
```console
cp /etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/websv.conf
```
#### Montaje del directorio NFS:
```console
mkdir -p /nfs/shared
mount 192.168.30.28:/var/nfs/shared /nfs/shared
```

- Crea el directorio `/nfs/shared` y monta el recurso compartido desde el servidor NFS (`192.168.30.28`).

  #### Automatización del montaje:
```console
echo "192.168.30.28:/var/nfs/general /nfs/general nfs auto,nofail,noatime,nolock,intr,tcp,actimeo=1800 0 0" | sudo tee -a /etc/fstab
mount -a
```

- Añade la configuración al archivo `/etc/fstab` para montar automáticamente el recurso NFS al iniciar el sistema.

#### Activación del nuevo sitio y reinicio de Apache:
```console
a2dissite 000-default.conf
a2ensite websv.conf
systemctl restart apache2
systemctl reload apache2
systemctl status apache2
```
- Desactiva el sitio por defecto, activa la nueva configuración y reinicia Apache para aplicar los cambios.

### 4. SGBD (sgbd.sh)
Este script configura un servidor MySQL, crea una base de datos y un usuario con privilegios específicos para acceder desde una red.
![sgbd sh1](https://github.com/user-attachments/assets/5df7f7ab-ca23-463f-adc7-0460148c3f69)

#### Instalación de MySQL:
```console
apt install mysql-server -y
apt update -y
apt install -y mysql-server
```

- Instala el servidor MySQL y actualiza los paquetes disponibles.

#### Configuración de MySQL para permitir conexiones remotas:
```console
sed -i "s/^bind-address\s*=.*/bind-address = 192.168.30.42/" /etc/mysql/mysql.conf.d/mysqld.cnf
```

- Modifica el archivo de configuración de MySQL (`mysqld.cnf`) para cambiar la dirección de enlace (`bind-address`) a `192.168.30.42`, lo que permite conexiones desde esa dirección específica.

#### Reinicio del servicio MySQL:
```console
sudo systemctl restart mysql
```
- Reinicia el servicio para aplicar los cambios en la configuración.

#### Creación de base de datos y usuario:
```console
mysql <<EOF
CREATE DATABASE db_wordpress;
CREATE USER 'david'@'192.168.30.%' IDENTIFIED BY 'S1234';
GRANT ALL PRIVILEGES ON db_wordpress.* TO 'david'@'192.168.30.%';
FLUSH PRIVILEGES;
EOF
```

- `CREATE DATABASE db_wordpress;`: Crea una base de datos llamada db_wordpress.
- `CREATE USER 'david'@'192.168.30.%' IDENTIFIED BY 'S1234';`: Crea un usuario david con acceso permitido desde cualquier host en la subred 192.168.30.% y le asigna la contraseña S1234.
- `GRANT ALL PRIVILEGES ON db_wordpress.* TO 'david'@'192.168.30.%';`: Otorga al usuario david todos los privilegios sobre la base de datos db_wordpress.
- `FLUSH PRIVILEGES;`: Recarga los privilegios para que los cambios surtan efecto inmediatamente.

## Pasos para Configurar la Infraestructura en AWS
### 1. Crear una VPC personalizada

- Navega a VPC > Crear VPC.
- Selecciona “VPC con subredes públicas y privadas” y define un rango CIDR (`10.0.0.0/16`), en mi caso (`192.168.30.0/24`).
![vpc](https://github.com/user-attachments/assets/eddb5844-e03b-4a8b-b8cd-d41ab8756d28)


### 2. Crear Subredes

- Crea una subred pública (`10.0.1.0/24`) para el balanceador, en mi caso (`192.168.30.0/28`).
 ![subred publica](https://github.com/user-attachments/assets/3a37da70-24c9-4277-aab5-91cb266bb990)

- Crea dos subredes privadas (`10.0.2.0/24` y `10.0.3.0/24`) para los servidores backend y la base de datos, en este caso para la red-interna1 donde se alojan los webservers y el nfs (`192.168.30.16/28`) y para la red-interna2 con la base de datos (192.168.30.32/28).
![image](https://github.com/user-attachments/assets/3e1ac01e-9a94-4e9c-baca-925b3e42b84f)
![red interna 2](https://github.com/user-attachments/assets/17439123-b7fa-4723-8a59-98c54e88d504)

## 3. Configurar el Internet Gateway 

- Enlaza un Internet Gateway a la VPC.
![puerta de enlace internet](https://github.com/user-attachments/assets/c5b88b8e-6598-4d75-acbc-61a48052afa6)

## 4. Configurar Tablas de Enrutamiento

- Asocia la subred pública a una tabla de enrutamiento pública con una ruta hacia el Internet Gateway.
 ![rutas publicas](https://github.com/user-attachments/assets/e103a1c7-249a-4e1a-b96b-ef3698c89389)

- Asocia las subredes privadas a una tabla de enrutamiento privada con una ruta hacia el NAT Gateway.
![rutas privadas](https://github.com/user-attachments/assets/e3898f47-38a9-4053-a198-c0c933bf4608)

## 5. Crear Grupos de Seguridad

- **Balanceador**: Permitir tráfico HTTP/HTTPS y SSH desde cualquier origen.
![reglas entrada balanceador](https://github.com/user-attachments/assets/757ed1e2-49c7-40b8-9a1d-0a61247618cc)

- **Backend**: Permitir tráfico HTTP desde el balanceador y acceso NFS desde el servidor NFS.
![reglas entrada webservers](https://github.com/user-attachments/assets/c5d91758-1948-4ac9-ae2d-f2a5653c60b8)

- **NFS**: Permitir conexiones NFS desde los servidores backend.
![reglas entrada nfs](https://github.com/user-attachments/assets/839b7c90-f38c-4f16-904a-6ae2f5fe8198)

- **Base de Datos**: Permitir tráfico MySQL desde los servidores backend.
![reglas de entrada sgbd](https://github.com/user-attachments/assets/f2b3bfdd-9133-44ea-bee1-ec8515a9cc74)

## 6. Crear Instancias EC2

- Balanceador en la subred pública.
- Web servers y NFS en la subred privada 1.
- Base de datos en la subred privada 2.

## 7. Asignar IP Elástica al Balanceador

- Reserva una IP elástica y asígnala a la instancia del balanceador.
![ip elastica](https://github.com/user-attachments/assets/c292bf34-41ba-4491-b5be-87fbe41d3c72)

  
## Resultado
A través de un navegador, nos conectaremos a nuestra aplicación poniendo https://wordpressdavidsc.myddns.me/
![pagina https](https://github.com/user-attachments/assets/a84c4ccc-029d-45fa-ae28-e52e8929b3b7)

También se podría acceder desde http://wordpressdavidsc.myddns.me/
![pagina http](https://github.com/user-attachments/assets/d4987fef-e303-4b4e-946a-329e0a9ea1c9)

##  Despliegue
- **Aprovisionar infraestructura en AWS** siguiendo los pasos anteriores.
- **Conectar vía SSH** a cada instancia y ejecutar los scripts de aprovisionamiento.

```console
./balanceador.sh
./nfs.sh
./webservers.sh
./sgbd.sh
```
- **Acceder a WordPress** utilizando el dominio apuntado a la IP elástica del balanceador.

## Conclusión
Este proyecto implementa un sitio WordPress en AWS siguiendo una arquitectura de tres capas para asegurar alta disponibilidad, escalabilidad y seguridad. El balanceador de carga distribuye el tráfico hacia los servidores backend, que comparten recursos mediante NFS, mientras que la base de datos está protegida en una red privada.

La automatización mediante scripts garantiza un despliegue rápido y consistente, reduciendo errores y facilitando futuras actualizaciones. En conjunto, la solución ofrece un entorno web robusto y preparado para escalar según la demanda.
