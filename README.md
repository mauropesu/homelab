# homelab

Personal lab for practicing RHEL administration, Ansible and AWX.

## Components

| Component | Platform | Access |
|---|---|---|
| ansible-node (Rocky 9) | OrbStack | `orb -m ansible-node` |
| app-node-01 (Rocky 9) | OrbStack | 192.168.139.223 |
| rhel9-main (RHEL 9.8) | Parallels | 10.211.55.23 |
| AWX 24.6.1 | OrbStack Kubernetes, namespace `awx` | http://localhost:30080 |

## Layout

- `ansible/`: inventory, playbooks and healthcheck. Run from ansible-node at `/Users/maopesu/Labs/homelab/ansible`.
- `awx/`: AWX Operator manifests. Apply with `kubectl apply -k awx/`.
