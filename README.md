# Infra code for deployment of unikernel

```
pacman -S install terraform doctl yq optipng
pip3 install python-digitalocean requests
doctl auth init
```

```
terraform import digitalocean_ssh_key.default SSH-ID
terraform import digitalocean_vpc.default VPC-ID

```


```
cd infra && terraform init && cd ..
export DO_TOKEN=xxxxx
export GRAFANA_CLOUD_USERNAME=xxxxx
export GRAFANA_CLOUD_PASSWORD=xxxxxx

```

```
make tf-apply
```
