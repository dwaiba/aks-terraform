#!/bin/sh

run_it () {
RELEASE="0.1"

## NOTE sh NOT bash. This script should be POSIX sh only, since don't
## know what shell the user has. Debian uses 'dash' for 'sh', for
## example.

PREFIX="/usr/local"

set -e
set -u

# Let's display everything on stderr.
exec 1>&2

echo -e "Please note terraform binary and your id_rsa.pub should be present in the present dir. and keep your Azure client_id and secret handy. Happy k8sing !\n"
read -p "Enter your name or BU Name for aks creation: " yournameorBU
echo $yournameorBU;
docker run -dti --name=azure-cli-python-$yournameorBU --restart=always azuresdk/azure-cli-python && docker cp terraform azure-cli-python-$yournameorBU:/ && docker cp id_rsa.pub azure-cli-python-$yournameorBU:/ && docker exec -ti azure-cli-python-$yournameorBU bash -c "az login && git clone https://github.com/dwaiba/aks-terraform && cp id_rsa.pub /aks-terraform/ && cp terraform /usr/bin && cd /aks-terraform/ && terraform init && terraform plan -out run.plan && terraform apply "run.plan" && bash";

trap - EXIT
}

run_it
