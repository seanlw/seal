#!/bin/bash

read -r -d '' usage <<EOF
Usage:
  seal NAME [options]

Options:
  -c, --cert string       Public certificate to use for encrypting secrets
  -e, --env string        If present, the .env file that references key=val pairs
  -f, --file string       If present, items that can be source from file
  --help                  Print this help message
  -l, --literal string    If present, the key and literal value to insert (i.e. key=val)
  -n, --namespace string  If present, the namespace scope for this CLI request

Example:
  seal my-secret --namespace default --literal foo=bar --cert public-cert.pem
EOF

mkdir /build

script_name=$(basename "$0")
secret_name=$1
long=env:,cert:,file:,namespace:,literal:,help
short=e:,c:,f:,n:,l:

envs=()
files=()
literals=()

TEMP=$(getopt -o $short --long $long --name "$script_name" -- "$@")
eval set -- "${TEMP}"
while :; do
  case "${1}" in
    -e | --env) envs+=($2); shift 2 ;;
    -c | --cert) cert=$2; shift 2 ;;
    -f | --file) files+=($2); shift 2 ;;
    -n | --namespace) namespace=$2; shift 2 ;;
    -l | --literal) literals+=($2); shift 2 ;;
    --help) echo "${usage}" 1>&2; exit ;;
    --) shift; break;;
    *)
      echo "Unknown option: ${1}"; exit 1;;
  esac
done

if [[ ! -z "$envs" ]]; then
  envs_temp=$"envs:\n"
  for i in "${envs[@]}"; do
    cp -f ${i} /build/${i}
    envs_temp=$"${envs_temp}    - ${i}\n"
  done
  envs_temp=$(printf "${envs_temp}")
fi

if [[ ! -z "$files" ]]; then
  files_temp="files:\n"
  for i in "${files[@]}"; do
    cp -f ${i} /build/${i}
    files_temp=$"${files_temp}    - ${i}\n"
  done
  files_temp=$(printf "${files_temp}")
fi

if [[ ! -z "$literals" ]]; then
  literals_temp=$"literals:\n"
  for i in "${literals[@]}"; do
    literals_temp=$"${literals_temp}    - ${i}\n"
  done
  literals_temp=$(printf "${literals_temp}")
fi

if [[ ! -z "$namespace" ]]; then
  namespace_temp=$(printf "namespace: ${namespace}")
fi

if [[ -f "$cert" ]]; then
  cert=$"--cert ${cert}"
elif [ -f "/certs/${cert}" ]; then
  cert=$"--cert /certs/${cert}"
elif [ -f "/certs/public-cert.pem" ]; then
  cert="--cert /certs/public-cert.pem"
else
  echo "No public certificate has been provided, try setting --cert <public-cert.pem>"
  exit 1
fi


cat >/build/kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

${namespace_temp}

generatorOptions:
  annotations:
    sealedsecrets.bitnami.com/managed: "true"
    sealedsecrets.bitnami.com/namespace-wide: "true"

secretGenerator:
  - name: ${secret_name}
    options:
      disableNameSuffixHash: true
    ${envs_temp}
    ${files_temp}
    ${literals_temp}
EOF

kustomize build /build | kubeseal ${cert} --format yaml