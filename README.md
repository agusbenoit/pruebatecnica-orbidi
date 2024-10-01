# pruebatecnica-orbidi

### Diagrama de infraestructura propuesta
![infrastructura](/prueba-orbidi.png "Infrastructura propuesta")

### Detalle

El objetivo de esta arquitectura es proporcionar el soporte adecuado para el despliegue de dos aplicaciones web, en entornos de desarrollo y produccion. A grandes rasgos se compone de dos VPCs aisladas, una para cada entorno. 
Para proporcionar alta disponibilidad y escalabilidad, las aplicaciones van a correr en dos clusters ECS (uno por entorno), y el trafico va a ser administrado por ALBs. De esta manera delegamos a AWS el mantenimiento de las instancias necesarias para correr las aplicaiones. 

Cada VPC cuenta con subnets publicas en mas de una zona de disponibilidad, donde se instancian los balanceadores de carga, y subnets privadas, donde corren los contenedores de ECS. 

Con este acercamiento logramos alta disponibilidad, ya que las aplicaciones estan distribuidas en multiples zonas de disponibilidad, el uso de ECS permite escalar las aplicaciones segun la demanda, y al correr los contenedores en subnets privadas solo el trafico del ALB es permitido, lo que eleva la seguridad.


## Terraform

Para lograr una infraestructura reutilizable, se va a partir de tres modulos principales que luego van a ser instanciados segun el entorno que se desea desplegar. Estos modulos son: 
- **networkin**: encargado de desplegar VPC y subnets
- **ecs_cluster**: encargado de desplegar el cluster ecs
- **load_balancer**: encargado de desplegar el balanceador de carga

#### Entornos

Dentro de la carpeta environments se encuentran los archivos de terraform que despliegan la infra para casa entorno. Estos entornos (dev y prod) comparten recursos para todas las apps que se van a desplegar. Estos recursos son la VPC y el cluster ECS. A su vez, cada app cuenta con su ALB y su target group. Para segmentar la configuracion, cada entorno cuenta con una carpeta `_global`, donde se definen los recursos VPC y cluster ECS, y luego una carpeta por cada app a desplegar (`simple-app1` y `simple-app2`) donde se configuran los recursos propios de cada app. 

Para resguardar el estado de terraform se configura el backend para que utilice `S3` y una tabla de `DynamoDB`. El script `tfbackendcfg.sh` se encarga de la creacion del bucket y la tabla, solicitando ademas la region donde se va a desplegar toda la infraestructura. Adicionalmente configura el nombre del bucket y esta region en los archivos de los entornos. 

Para cada App, en su `main.tf`, se crean los siguientes recursos propios de la app:
- Load balancer
- Security group para ALB
- Security group para servicio de ECS
- Rol para la tarea de ECS
- Definicion de tarea de ECS
- Servicio de ECS

Con esto se cubre la creacion de recursos principales para correr cada aplicacion.

### Aplicaciones

En el mismo repo se encuentra el codigo de cada aplicacion. Se creo en ambas aplicaciones un `Dockerfile` y un `pipeline.sh`. Este ultimo archivo simula una pipeline de CICD.

#### Dockerfile
```bash
FROM python:3.9-slim

RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY ./requirements.txt .

RUN pip install --no-cache-dir --upgrade -r requirements.txt

COPY main.py .

EXPOSE 8000

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]
```

Se parte de una imagen slim de python 3.9 para crear una imagen liviana. Se instala el comand `curl` que luego sirve de healthcheck cuando se crea el servicio en ECS. Se copian y se instalan los requirements. Se copia el archivo princial de la aplicacion y se expone el puerto 8000 (puerto por defecto de fastAPI). Finalmente se corre el comando `uvicorn main:app --host 0.0.0.0 --port 8000 --reload` para permitir conexiones externas a la aplicacion. 

#### Pipeline.sh
El proposito de este script es simular un pipeline como podria ser GitHub Actions. Comienza con el build de la imagen de la app, partiendo del `Dockerfile`, luego se autentica en el registro privado de AWS y sube la imagen. Luego de esto utiliza esta nueva imagen para registrar una nueva task-definition de ECS y actualiza el servicio para que utilice esta nueva definicion, logrando de esta forma el despliegue de la ultima imagen creada. 

Para que este pipeline pueda funcionar, se deben configurar el URI del repositorio de imagenes de la APP y el ARN del rol de ejecucion de la tarea. De esta configuracion se encarga el script `pipelineconfig.sh` que, al ejecutarlo, por cada app crea un ECR, un log group para CloudWatch y obtiene el ARN del rol mediante terraform.

## Lanzamiento de la infraestructura y aplicaciones

Se configuro el script `init.sh` para crear la infraestructura y desplegar las aplicaciones de manera automatica. Al iniciar el script se solicitaran solo dos datos:
- Nombre de bucket para guardar el estado de terraform
- Region de AWS donde se quiere desplegar la infraestructura

Una vez ingresado estos datos, procede a la creacion del bucket y una tabla DynamoDB mediante el script `tfbackendcfg.sh`. El siguiente paso es el despliegue de cada componente, comenzando por los recursos comunes en **environments/dev/_global**, y luego los recursos de cada simple-app. Con los recursos de cada app se crea una task-definition generica, con un container Nginx. Estas definiciones tienen configurado `lifecycle = ignore_change` ya que se crean con terraform pero luego son modificadas por los pipelines, quienes se encargan de configurar el container de cada app con su respectiva imagen buildeada desde su `Dockerfile`.

Con la infraestructura ya lista, el proximo paso de `init.sh` es configurar los pipelines de cada app con el script `pipelineconfig.sh`. Realizado este paso solo queda iniciar el pipeline de cada app, donde se realiza el build, tag y push de cada imagen, y la actualizacion de la task-definition. 

El script finaliza entregando por pantalla las direcciones DNS de cada ALB para cada app:
```bash
Simple-app1 http://simple-app1-alb-dev-XXXXXXXX.us-east-1.elb.amazonaws.com
Simple-app2 http://simple-app2-alb-dev-XXXXXXXX.us-east-1.elb.amazonaws.com
```
**NOTA:** puede demorar un par de minutos la actualizacion de la task definition, lo que provoca que al ingresar a la url de error 502 hasta que finalmente se actualiza con el contenedor.

### Eliminacion de apps e infraestructura

Asi como se configuro `init.sh` para la creacin de todos los recursos, el script `clean.sh`realiza los pasos inversos, eliminando los recursos de Terraform, los registros ECR y elimina los archivos .terraform de cada componente. Para que este script pueda correr sin interaccion del usuario, el bucket del estado de terraform se creó sin versionado. Esto no es una buena practica pero se hizo para fines practicos. 