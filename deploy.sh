ssh -i $KEY $USER@$HOST \
    "sudo yum install docker -y && service docker start && sudo docker run --rm -d -p 80:8888 jpabloms2/masterlab"
