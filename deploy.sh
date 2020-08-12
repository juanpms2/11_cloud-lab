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
