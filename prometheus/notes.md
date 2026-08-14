# Prometheus

- Prometheus collects metrics from monitored targets by scraping metrics HTTP endpoints on these targets
- Also exposes date in the same way
- so can scrape and monitor its own health

1. Create a container: ```docker create --name config docker.io/prom/prometheus:v3.2.1```
2. Copy config we just created: ```docker cp config:/etc/prometheus/prometheus.yml .```
3. Examine yaml: ```cat prometheus.yml```
4. Remove dockor container: ```docker rm config```
   1. Prometheous also has a flag based config setting: ```docker run --rm docker.io/prom/prometheus:v3.2.1 -h```
5. Create Docker network to allow you to connect to container you want to monitor: ```docker network create --driver bridge lab```
6. Start Prometheous with default config file: ```docker run -d -p 9090:9090 --name prometheus -h prometheus --net lab docker.io/prom/prometheus:v3.2.1 ```
7. View: ```http://<machine-ip>:9090/status``` or ```http://192.168.56.1:9090/targets``` to verify prometheous can still scrape itself
   1. run ``ipconfig`` and get IPv4 Address

## monitoring a Demo service

1. Clone git directory: ``git clone --depth=1 https://github.com/lftraining/LFS241.git``
2. Change into "demo-service-source" : ``cd ~/LFS241/demo-service-source``
3. Build demo service image: ``docker build -t prometheus-demo-service .``
4. run 3 instances of the demo service in the background: ``docker run -d --name d1 -h d1 --net lab prometheus-demo-service`` , ``docker run -d --name d2 -h d2 --net lab prometheus-demo-service`` & ``docker run -d --name d3 -h d3 --net lab prometheus-demo-service``
5. so these 3 instances now create synthetic metrics about themselves
   1. Inspect lab network to get IP adress: ```docker network inspect lab```
   2. now run ```http://<container-ip>:8080/metrics```
   3. ``curl http://$(docker inspect d1 -f '{{.NetworkSettings.Networks.lab.IPAddress}}'):8080/metrics``
   4. Or run curl from inside your prometheus container ``docker exec -it prometheus wget -qO- http://d1:8080/metrics``
   5. add a new job name and targets to propmetheous.yaml file
   6. remove old prometheous container: ``docker rm --force prometheus``
   7. map this file into a prometheous container using volume mount : ```docker run -d -p 9090:9090 --name prometheus -h prometheus --net lab -v ~/prometheus/:/etc/prometheus/ docker.io/prom/prometheus:v3.2.1 ``` or ```docker run -d -p 9090:9090 --name prometheus -h prometheus --net lab -v C:/AKS_LABS/prometheus:/etc/prometheus prom/prometheus:v3.2.1```
      1. In Docker, ``-v`` stands for Volume (specifically a bind mount)
      2. It mounts a directory from your host machine into the container so the container can read or save files on your host computer.
      3. ``~/prometheus/`` (Host Path): The folder on your local computer containing your prometheus.yml file.
      4. ``/etc/prometheus/`` (Container Path): The folder inside the container where the Prometheus service looks for its configuration files.
   8. View: ```http://<machine-ip>:9090/status``` or ```http://192.168.56.1:9090/targets``` to verify prometheous can still scrape itself
      1. run ``ipconfig`` and get IPv4 Address

## Selecting Series

- can select a series by calling the metric name in query E.G. demo_api_request_duration_seconds_count