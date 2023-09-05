# About

Kubernetes KVM cluster


# Build the images (Ubuntu 20.04 based)

Go to the Packer folder and build the node images

```
cd Packer && packer init . && packer build .
```


# Deployment

Ensure terraform is installed (https://developer.hashicorp.com/terraform/downloads)

```
./00-bootstrap-k8s.sh
./01-bootstrap-k8s-infra.sh
....
```


# /etc/hosts

```
192.168.180.2	lb		    lb.k8s.local
192.168.180.10	cp		    cp.k8s.local
192.168.180.11	worker1		worker1.k8s.local
192.168.180.12	worker2		worker2.k8s.local
192.168.180.13	worker3		worker3.k8s.local

192.168.180.2	dashboard.k8s.local grafana.k8s.local prometheus.k8s.local alertmanager.k8s.local mattermost.k8s.local

```

# Endpoints (After/If deployed)

* Control plane (cp.k8s.local)
* Dashboard -> https://dashboard.k8s.local/
* Grafana (metrics & logs UI) -> https://grafana.k8s.local/
* Prometheus (Metrics) -> https://prometheus.k8s.local/
* Prometheus Alertmanager (Metrics alerts) -> https://alertmanager.k8s.local
