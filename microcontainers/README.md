# microcontainers
One of the reasons that Docker has become so popular is because of

![microservices](microservices.jpg)

https://martinfowler.com/articles/microservices.html

http://microservices.io/patterns/index.html

however if, for example, you go ahead and naively pull the official Node image from dockerhub
````
docker pull node
````
and then do
````
docker images
````
You might be surprised to note that the image is **663MB**.

and your microservice *just might* not be  quite as "micro" as you were expecting!

![toobig](toobig.jpg)

The idea of a microcontainer is that it contains only the OS libraries and language dependencies required to run an application and the application itself. Nothing more.

https://www.iron.io/microcontainers-tiny-portable-containers/

## Enter Alpine
Fortunately Docker has recently started giving the option using [Alpine](https://alpinelinux.org/) as the base for official images which makes things **a lot** smaller.

````
docker pull node:alpine
````
and then do
````
docker images
````
Which is significantly smaller than the previous image weighing in at only 54.6 MB.
