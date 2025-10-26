#!/bin/bash
set -eu

function PrintHelp {
cat << EOF
$0 [OPTION]... GIT_URL
-g
    Comma separated list of Ansible groups (default: agent)
-r
    Git ref (default: main)
EOF
}



## Parse args ##

trap PrintHelp EXIT

while getopts ":g:r:" opt; do
  case "$opt" in
    g) ansibleGroups="$OPTARG";;
    r) gitRef="$OPTARG";;
    *) PrintHelp && exit 1;;
  esac
done

shift $((OPTIND-1))


gitUrl="$1"
gitRef=${gitRef-main}
ansibleGroups=${ansibleGroups-agent}

trap - EXIT



## Paths ##

confDir=/etc/ansible-agent
venvDir=/usr/local/ansible-agent
venvPython="$venvDir/bin/python3"
inventory="$confDir/inventory"

mkdir -p "$confDir"



## Setup venv ##

if [[ ! -f "$venvPython" ]]; then
  /usr/bin/python3 -m venv "$venvDir"
fi

"$venvPython" -m pip install --require-hashes -r requirements.txt

/usr/bin/semanage fcontext -a -t bin_t "$venvDir/bin(/.*)?"
/usr/bin/semanage fcontext -a -t lib_t "$venvDir/lib(/.*)?"
/usr/bin/restorecon -R "$venvDir"



## Setup inventory ##

cat << EOF > "$inventory"
[all:vars]
ansible_connection=local
ansible_python_interpreter=$venvPython
git_ref=$gitRef
git_url=$gitUrl
EOF

readarray -d , groups <<< "agent,${3-}"
for group in "${groups[@]}"; do
  group=$(echo "$group" | tr -dc "[:alpha:]")
  if [[ -n "$group" ]]; then
    { echo; echo "[$group]"; echo "127.0.0.1"; } >> "$inventory"
  fi
done


## Run playbook ##

"$venvDir/bin/ansible-pull" --url "$gitUrl" --checkout "$gitRef" --inventory "$inventory" playbook.yaml
