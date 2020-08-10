#!/bin/bash
yes
echo "Kill container..."
sudo docker kill masterlab
echo "run new container"
sudo docker run --rm -d -p 80:8888 --name masterlab jpabloms2/masterlemoncode_cloud
echo "finish update"
exit
