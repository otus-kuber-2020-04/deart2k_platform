#!/bin/sh

docker build $@ --tag deart/kubernetes-monitoring_nginx:latest  .
docker push deart/kubernetes-monitoring_nginx
