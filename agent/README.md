# Ansible Agent

## Install

```shell
ref=main
baseUrl=https://raw.githubusercontent.com/doughom/homelab/refs/heads

curl -fLO "$baseUrl/$ref/agent/requirements.txt"
curl -fLs "$baseUrl/$ref/agent/install.sh" | sudo bash -s - -r $ref https://github.com/doughom/homelab
```
