# Configuring Prometheous

Create a container image : docker create --name config docker.io/prom/prometheus:v3.2.1

Copy prometheus configuration file into the config container:
docker cp prometheus.yml config:/etc/prometheus/prometheus.yml

Creatte a docker network for prometheous instance
docker network create --driver bridge lab