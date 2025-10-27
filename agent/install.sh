#!/bin/bash

# install.sh [OPTION]... GIT_URL
# -g
#     Comma separated list of Ansible groups (default: agent)
# -r
#     Git ref (default: main)

set -eu

## Parse args ##

while getopts ":g:r:" opt; do
  case "$opt" in
  g) ansibleGroups="$OPTARG" ;;
  r) gitRef="$OPTARG" ;;
  *) echo "Invalid option: -$opt" && exit 1 ;;
  esac
done

shift $((OPTIND - 1))

gitUrl="$1"
gitRef=${gitRef-main}
ansibleGroups="agent,${ansibleGroups-}"

## Install prerequisites ##

# shellcheck disable=SC1091
source /etc/os-release
releaseId=${ID_LIKE-$ID}

if [[ "$releaseId" =~ debian ]]; then
  apt-get update
  apt-get -y --no-install-recommends install python3-venv
elif [[ "$releaseId" =~ fedora ]]; then
  dnf -y install policycoreutils-python-utils
else
  echo "$releaseId not supported" && exit 1
fi

## Setup venv ##

venvDir=/usr/local/ansible-agent
venvPython="$venvDir/bin/python3"

if [[ ! -f "$venvPython" ]]; then
  python3 -m venv "$venvDir"
fi

"$venvPython" -m pip install --require-hashes -r requirements.txt

if [[ "$releaseId" =~ fedora ]]; then
  semanage fcontext -a -t bin_t "$venvDir/bin(/.*)?"
  semanage fcontext -a -t lib_t "$venvDir/lib(/.*)?"
  restorecon -R "$venvDir"
fi

## Setup temporary inventory ##

inventory=$(mktemp)
cat <<EOF >"$inventory"
[agent:vars]
ansible_connection=local
ansible_python_interpreter=/usr/local/ansible-agent/bin/python3

[agent]
$(hostname)
EOF

## Run playbook ##

# shellcheck disable=SC2001
groups=$(echo "$ansibleGroups" | sed "s/,$//g")

"$venvDir/bin/ansible-pull" \
  --url "$gitUrl" \
  --checkout "$gitRef" \
  --inventory "$inventory" \
  --extra-vars "{\"agent_inventory_groups\": [\"${groups//,/\",\"}\"], \"agent_git_url\": \"$gitUrl\", \"agent_git_ref\": \"$gitRef\"}" \
  playbook.yml

rm "$inventory"
