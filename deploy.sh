echo "Kill container..."
sudo docker kill jpabloms2/masterlab
echo "Pull imagen docker hub"
sudo docker pull -t jpabloms2/masterlemoncode_cloud
echo "run new container"
sudo docker run --rm -d -p 80:8888 --name jpabloms2/masterlab jpabloms2/masterlemoncode_cloud
echo "finish update"
