#!/bin/sh
sudo docker kill squid3
sudo docker rm squid3
sudo docker run -h proxy.docker.dev -p 3128:3128 --name squid3 termie/squid3-ssl

