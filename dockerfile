FROM ubuntu:18.04

WORKDIR /opt/app

COPY . .

RUN apt-get update

RUN apt-get install curl -y

RUN curl -sL https://deb.nodesource.com/setup_10.x -o nodesource_setup.sh

RUN bash nodesource_setup.sh

RUN apt-get install nodejs -y

RUN npm install --only=production

EXPOSE 8888

CMD ["npm", "start"]



