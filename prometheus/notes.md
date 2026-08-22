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
- ``demo_ap_request_duration_secons_count{job ="demo"}``
- ``demo_ap_request_duration_secons_count{method="GET", status="200"}``
- ``rate(demo_api_request_duration_seconds_count{job="demo"}[5m])``
- ``irate(demo_api_request_duration_seconds_count{job="demo"}[5m])``
- ``increase(demo_api_request_duration_seconds_count{job="demo"}[1h])``
- ``deriv(demo_disk_usage_bytes{job="demo"}[10m])``
- ``predict_linear(demo_disk_usage_bytes{job="demo"}[15m],36000)``
- ``sum(rate(demo_api_request_duration_seconds_count{job="demo"}[5m]))``

## setting up grafana

- ``docker run -d -p 3000:3000 --name grafanna -h grafana --net lab docker.io/grafana/grafana:11.6.0``
- go to ``http://<machine-ip>:3000/`` -> ```http://192.168.56.1:3000/```
- login using default admin username and password
create prometheous datasource

## node exporter (sysem level)

- Start Node exporter: `` docker run -d --name node-exporter --net host --pid host -v /:/host:ro,rslave docker.io/prom/node-exporter:v1.9.1 --path.rootfs=/host``
- or ``docker run -d --name node-exporter -p 9100:9100 docker.io/prom/node-exporter:v1.9.1``
- go to ``http://<machine-ip>:9100/`` -> ```http://192.168.56.1:9100/```
- Add the following to scrape config

``` yaml
  - job_name: "node"
    static_configs:
      - targets: ["host.docker.internal:9100"]
``` 

- Then restart prometheous ``docker restart prometheus``
- ``rate(node_cpu_seconds_total{job="node"}[1m])``
- ``sum without(cpu) (rate(node_cpu_seconds_total{mode!="idle",job="node"}[1m]))``
- ``(node_filesystem_free_bytes / node_filesystem_size_bytes)*100``
- `` node_time_seconds - timestamp(node_time_seconds)``

## cAdvisor (Container level)

- run the following

```yaml
docker run -d --name cadvisor -h cadvisor --net lab -v/:/rootfs:ro -v/var/run:/var/run:ro -v/sys:/sys:ro -v/var/lib/docker/:/var/lib/docker:ro -v/dev/disk/:/dev/disk:ro gcr.io/cadvisor/cadvisor:v0.52.1
```

- go to ``http://<machine-ip>:8080/metrics/`` -> ```http://192.168.56.1:8080/metrics/```
- Add the following to scrape config

```yaml
  - job_name: "cadvisor"
    static_configs:
      - targets: ["cadvisor:8080"]
```

- Then restart prometheous ``docker restart prometheus``
- ``container_cpu_usage_seconds_total``
- ``rate(container_cpu_usage_seconds_total[1m])``
- ``sum without(cpu) (rate(container_cpu_usage_seconds_total{name="grafana"}[1m]))``
- ``container_memory_usage_bytes{name="grafana"}``

## instrumentation examples

- Clone the following : ``git clone --depth=1 https://github.com/lftraining/LFS241.git``
- Enter the following ``cd LFS241/instrumentation-exercise``
- Enter python
- ``docker build -t py-lab-app .``
- ``docker run -d --net lab --name lab-app -h lab-app -e LC_ALL=Cpy-lab-app``

## trouble shooting

- run ``docker start prometheus d1 d2 d3`` if you exit container to start back up again
- find out whats running on port 3000 ``Get-NetTCPConnection -LocalPort 3000 | Select-Object LocalAddress, LocalPort, State, OwningProcess``
- stop owning process ``Stop-Process -Id 1234 -Force`` 

## Main Prometheus instalation options

- Can install from binary/source -> ``https://prometheus.io/download/``
   - Create rest drectory: ``mkdir prom-binary`
   - Change into directory
   - Download Binary form: ``https://prometheus.io/download/``
   - ``wget link``
   - Decompress the bianary: tar -xvf <filename>
- packange manager: ``sudo apt install prometheus``
   - ``install node_exporter: sudo apt-get update && sudo apt-get install -y prometheus-node-exporter && sudo systemctl enable --now prometheus-node-exporter``
- docker container
- scripted install

### Basic usage

1. Acess directory
2. run it: ./prometheus
   1. To make it executable if not already use ``chmod +x prometheus``
   2. ``./prometheus --config.file="prometheus.yml" --web.listen-address="<iP network:9090>" ``
   3. ip network 0.0.0.0 gives acess to all ports
3. Access it : ``http://localhost:9090`` or ``http://<Server IP Adress>:9090``
4. Enter query ``up``
5. To mak script executable ``chmod +x <name of script>`` -> run with sudo./
6. Then run with ``sudo ./<script>``
7. Type ``prometheus --version`` to verify or ``systemctl status prometheus.service`` or ``curl http://localhost:9090``
8. ``man prometheus`` -> to get manual page
9. ``prometheus --help`` or ``promtool``
10. 







