# List all recipes
default:
    @just --list

# Boostrap cluster
bootstrap: bootstrap-cilium bootstrap-flux

# Bootstrap Cilium
bootstrap-cilium:
    helm upgrade --install \
        cilium \
        cilium --repo https://helm.cilium.io \
        --namespace kube-system \
        --wait

# Boostrap Flux
bootstrap-flux:
    #!/usr/bin/env bash
    set -euxo pipefail
    private_key_file=$(mktemp)
    trap "rm ${private_key_file}" EXIT
    echo -n "${BOOTSTRAP_PRIVATE_KEY}" >"${private_key_file}"
    flux bootstrap git \
        --url=ssh://git@github.com/veselabs/homelab-platform \
        --branch=master \
        --private-key-file="${private_key_file}" \
        --path=clusters/homelab
