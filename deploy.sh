#!/bin/bash
ssh -i $KEY ec2-user@ec2-63-32-112-235.eu-west-1.compute.amazonaws.com \
echo "Kill container..."
sudo docker kill masterlab
echo "run new container"
sudo docker run --rm -d -p 80:8888 --name masterlab jpabloms2/masterlemoncode_cloud
echo "finish update"
exit
