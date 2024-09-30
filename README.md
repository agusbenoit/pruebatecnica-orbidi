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