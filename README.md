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

### 2. Servidor NFS (nfs.sh)
Configura NFS para compartir el contenido de WordPress.
![nfs sh 1](https://github.com/user-attachments/assets/1b116d0c-83c7-445c-9287-2b40bbd63de0)



## Resultado
A través de un navegador, nos conectaremos a nuestra aplicación poniendo hhtp://localhost:8080

![Lamp](https://github.com/user-attachments/assets/a449bc02-9a7a-408d-86ed-01009820aaef)

Para ver que está completamente funcional, crearemos un usuario.

![creacion usuario](https://github.com/user-attachments/assets/41fa999a-f09c-4c23-ac4a-f27124be29fb)
![usuario creado](https://github.com/user-attachments/assets/5bd57349-4953-43ab-a4a3-2a7a8f26f505)

Comprobaremos en nuestra base de datos que el usuario creado se ha añadido.

![pablo](https://github.com/user-attachments/assets/1253ecff-73e9-41ae-80a7-5429a853f80c)

## Como usar el proyecto
-**Clonar el proyecto**

-**Ejecutar vagrant up --provision para crear las máquinas y configurarlas**

-**Accede al servidor Apache a través de http://localhost:8080**

-**Usar la aplicación**

## Conclusión
Este proyecto en Vagrant proporciona una estructura para desplegar una pila LAMP en dos niveles, una VM dedicada a servidor web y otra con la base de datos, que simula un entorno real para pruebas o desarrollo.
