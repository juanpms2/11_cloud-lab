# PRÁCTICAS MÓDULO CLOUD

[![Build Status](https://travis-ci.org/juanpms2/11_cloud-lab.svg?branch=master)](https://travis-ci.org/juanpms2/11_cloud-lab)

## Preparación

- Cuenta de [Docker Hub](https://hub.docker.com/)
- Cuenta de [AWS](http://aws.amazon.com/)

## Práctica 1

Dado [este proyecto en NodeJS](https://github.com/Lemoncode/cloud-lab), crea su Dockerfile sabiendo que nos han pedido como imagen base ubuntu:18.04, versión 10 de NodeJS, el 8888 será el puerto donde exponga la comunicación la applicación, la señal de _STOP_ debe llegarle a la aplicación y el contenedor podría ser iniciado con cualquier proceso.

## Práctica 2

Sube la imagen de Docker a DockerHub.

## Práctica 3

Automatiza el proceso de creación de la imagen de Docker y su subida a Docker Hub después de cada cambio en el repositorio utitlizando Travis CI.

## Práctica 4

Crea un servidor y despliega la imagen de Docker en AWS utilizando Terraform.

### Adicionalmente se ha configurado y añadido el código necesario para el proceso de despliegue continuo. De esta manera cada cambio realizado en la aplicación se verá reflejado automáticamente en el servidor de producción.

# Documentación

Para este ejercicio se ha utilizado Git bash y el subsistema wls2 de Windows con Debian instalado.

Como opinión personal, aunque es posible trabajar con esto, es más recomendable utilizar directamente un sistema Linux.

## Docker

Instalamos Docker en nuestra máquina y nos creamos una cuenta de docker hub la cual utilizaremos como repositorio de nuestras imágenes y como "tienda de imágenes".

Creamos el archivo `dockerfile` desde el cual montaremos nuestra imagen con las características requeridas. En este caso partimos de una imagen Ubuntu 18.04 a la cual instalamos Node 10.0 y el resto de características requeridas en la práctica.

## AWS

Una vez creada nuestra cuenta en AWS crearemos un usuario y el sistema nos dará un par de claves las cuales guardaremos ya que no se vuelven a mostrar.

Desde la consola de administración creamos el par de claves (llave pública y privada) y nos descargamos nuestra huella digital privada, en nuestro caso el tipo `.pem` para la conexión SSH.

Ambos, certificado y claves se utilizarán posteriormente para realizar el despliegue desde Terraform o la conexión vía SSH.

En este caso la creación y despliegue no se realiza desde la consola de AWS sino desde Terraform.

## Terraform

El código de despliegue y creación de la imagen con Terraform por seguridad no se incluye en el repositorio. A continuación se detallan algunos aspectos que documentan su uso y programación:

- En el raíz del proyecto hemos creado el directorio terraform que contendrá toda la configuración y archivos necesarios para el despliegue.

- Creamos el archivo `main.tf` que contiene toda la programación y automatización del despliegue en AWS. En este caso se utiliza el servicio EC2 y una imagen de tipo t2-micro que nos levanta un servidor Linux el cual ya lleva pre-instalado parte de lo que necesitamos. En este caso nos interesa Docker.
- Hemos creado un script en bash el cual nos despliegua nuestro contenedor Docker en la máquina EC2. Este archivo es requerido en `main.tf`.

```bash
#!/bin/bash

sudo yum install docker -y
sudo usermod -aG docker ec2-user
sudo service docker start
sudo docker run --rm -d -p 80:8888 --name masterlab jpabloms2/masterlemoncode_cloud
```

- Añadimos al directorio terraform nuestra llave privada `.pem` que creamos en AWS.

Los siguientes comandos son los utizados para realizar el despliegue automatizado. Antes de ejecutarlos añadiremos las claves que guardamos al crear el usuario en AWS para que terraform pueda utilizarlas y no tener que añadirlas con cada comando:

```
export AWS_ACCESS_KEY_ID=XXXXXXXXXXXXXX
export AWS_SECRET_ACCESS_KEY=XXXXXXXXXXXXXXXXXXX

```

Y ejecutamos el despliegue:

```
terraform init
```

```
terraform plan
```

```
terraform apply
```

Una vez completados podremos ver cómo en nuestra consola de AWS se ha creado la imagen de nuestro servidor y podremos acceder a nuestra aplicación en el navegador desde la ip que nos proporciona.

## Travis CI

Hemos utilizado Travis conectado a nuestro repositorio de Github y docker hub para la integración y el despliegue continuo, esto nos permitirá que cualquier cambio aprobado en nuestra aplicación se verá reflejado de manera inmediata.

La siguiente configuración actualiza nuestra imagen docker en nuestro repositorio docker hub y realiza el despliegue de los cambios realizados a nuestra aplicación en nuestro servidor de AWS.

- La parte de docker: crea la imagen, loging en docker hub, nombra la imagen y la sube.
- La parte de despliegue continuo en AWS:

  - <b style="color:red">Importante encriptar nuestra clave privada antes de subirla a nuestro repositorio</b>
  - Tenemos que instalar Travis cli en nuestro sistema. [Aquí la documentación](https://github.com/travis-ci/travis.rb)
  - Una vez instalado encriptamos la clave, añadimos las llaves a nuestra zona segura de Travis y añadimos a github la clave encriptada.

  ```bash
    travis encrypt-file myClave.pem --add
    git add myClave.pem.enc
  ```

  - Antes del despliegue utilizamos openssl para desencriptar la clave, la almacenamos en una carpeta temporal y la dejamos preparada para la conexión SSH, de esta manera no tendremos que añadirla en el comando de conexión.
  - En el comando de conexión SSH se han añadido los siguientes parámetros `-o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no` para que la conexión sea directa, sino tendremos que indicarle de manera explícita un sí y dado que es una conexión automatizada esto no sería posible y fallaría.
  - Una vez realizada la conexión SSH se llama a un script en bash el cual vuelve a hacer el despliegue de nuestra imagen de docker con los cambios de nuestra aplicación ya actualizados.

```yml
  #.travis.yml

  sudo: required
  services:
  - docker
  script:
  - docker build -t labcloud .
  after_success:
  - docker login -u $DOCKER_USER -p $DOCKER_PASSWORD
  - docker tag labcloud $DOCKER_USER/masterlemoncode_cloud
  - docker push $DOCKER_USER/masterlemoncode_cloud
  before_deploy:
  - openssl aes-256-cbc -K $encrypted_6a109d58e6dc_key -iv $encrypted_6a109d58e6dc_iv -in masterlab.pem.enc -out /tmp/masterlab.pem -d
  - eval "$(ssh-agent -s)"
  - chmod 600 /tmp/masterlab.pem
  - ssh-add /tmp/masterlab.pem
  deploy:
  provider: script
  skip_cleanup: true
  script: ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ec2-user@54.154.60.189 "bash -s" < deploy.sh
  on:
      branch: master

```

```bash
#deploy.sh

#!/bin/bash

sudo yum update
echo "Kill container..."
docker kill masterlab
echo "delete docker image"
docker rmi -f jpabloms2/masterlemoncode_cloud
echo "run new container"
sudo docker run --rm -d -p 80:8888 --name masterlab jpabloms2/masterlemoncode_cloud
echo "finish update"
exit
```
