#!/bin/bash


DOCKER_LOGIN=andriykalashnykov

docker build . -t spring-petclinic

docker tag spring-petclinic $DOCKER_LOGIN/spring-petclinic:latest

docker login -u $DOCKER_LOGIN

docker push $DOCKER_LOGIN/spring-petclinic