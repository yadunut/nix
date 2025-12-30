# Kubernetes The Hard Way - NixOS

This module sets up a Kubernetes cluster from scratch using NixOS and clan.

## Architecture

- **Control Plane**: API Server, Controller Manager, Scheduler, etcd
- **Compute Nodes**: Kubelet, containerd
- **Networking**: IPv6-only cluster with Cilium CNI

## Cluster Configuration

| Setting | Value |
|---------|-------|
| Cluster CIDR (Pods) | `fd00:10:96::/48` |
| Service CIDR | `fd00:10:97::/108` |
| Cluster Domain | `k8s.internal` |
| API Server Port | `6443` |

## Post-Installation: CNI Setup

After deploying the NixOS configuration, nodes will be in `NotReady` state until a CNI plugin is installed.

### Prerequisites

1. Ensure the cluster is deployed and services are running:
   ```bash
   # On a controller node
   systemctl status kube-apiserver
   systemctl status etcd
   ```

2. Set up kubectl access:
   ```bash
   # Kubeconfig is auto-symlinked to ~/.kube/config for root and yadunut users
   kubectl get nodes  # Should show nodes in NotReady state
   ```

### Install Cilium CNI

We use Cilium as the CNI plugin with kube-proxy replacement enabled.

1. **Install Cilium** (run from a controller node or machine with cluster access):

   ```bash
   # Get the API server IP (ZeroTier IP of the controller node)
   API_SERVER_IP="<controller-zerotier-ip>"

   nix run "nixpkgs#cilium-cli" -- install \
     --set ipam.mode=kubernetes \
     --set kubeProxyReplacement=true \
     --set k8sServiceHost="${API_SERVER_IP}" \
     --set k8sServicePort=6443 \
     --set ipv6.enabled=true \
     --set ipv4.enabled=false \
     --set routingMode=native \
     --set ipv6NativeRoutingCIDR=fd00:10:96::/48 \
     --set autoDirectNodeRoutes=true \
     --set bpf.masquerade=true \
     --set enableIPv6Masquerade=true \
     --set operator.replicas=1 \
     --set hubble.enabled=true \
     --set hubble.relay.enabled=true \
     --set hubble.ui.enabled=true \
     --set hubble.peerService.clusterDomain=k8s.internal
   ```

2. **Wait for Cilium to be ready**:

   ```bash
   nix run "nixpkgs#cilium-cli" -- status --wait
   ```

3. **Verify nodes are Ready**:

   ```bash
   kubectl get nodes
   # All nodes should now show Ready status
   ```

### Verify Cilium Installation

```bash
# Check Cilium status
nix run "nixpkgs#cilium-cli" -- status

# Run connectivity test (optional, takes a few minutes)
nix run "nixpkgs#cilium-cli" -- connectivity test

# Check Cilium pods
kubectl -n kube-system get pods -l k8s-app=cilium
```

### Deploy CoreDNS

CoreDNS provides cluster DNS for service discovery. Deploy it after Cilium:

```bash
# Or if running from the repo root:
kubectl apply -f modules/kubernetes/manifests/coredns.yaml

# Verify CoreDNS is running
kubectl -n kube-system get pods -l k8s-app=kube-dns

# Test DNS resolution
kubectl run test-dns --rm -i --restart=Never --image=busybox:1.28 -- nslookup kubernetes.default.svc.k8s.internal
```

The CoreDNS service uses ClusterIP `fd00:10:97::a` (the 10th IP in the service CIDR), which matches the kubelet's `clusterDNS` configuration.

### Access Hubble UI (Optional)

Hubble provides observability for network traffic:

```bash
# Port-forward Hubble UI
nix run "nixpkgs#cilium-cli" -- hubble ui

# Or manually:
kubectl -n kube-system port-forward svc/hubble-ui 12000:80
# Then open http://localhost:12000
```

## Troubleshooting

### Nodes stuck in NotReady

1. Check kubelet logs:
   ```bash
   journalctl -u kubelet -f
   ```

2. Check CNI configuration:
   ```bash
   ls -la /etc/cni/net.d/
   ls -la /opt/cni/bin/
   ```

3. Check Cilium agent logs:
   ```bash
   kubectl -n kube-system logs -l k8s-app=cilium --tail=100
   ```

### API Server connectivity issues

1. Verify API server is running:
   ```bash
   systemctl status kube-apiserver
   curl -k https://[<node-ip>]:6443/healthz
   ```

2. Check certificates:
   ```bash
   openssl x509 -in /var/lib/kubernetes/pki/apiserver.crt -text -noout | grep -A1 "Subject:"
   ```

### Cilium installation fails

1. Check if kube-proxy is running (it shouldn't be with kubeProxyReplacement=true):
   ```bash
   kubectl -n kube-system get pods | grep kube-proxy
   ```

2. Reinstall Cilium:
   ```bash
   nix run "nixpkgs#cilium-cli" -- uninstall
   # Then run install command again
   ```

## References

- [Kubernetes The Hard Way](https://github.com/kelseyhightower/kubernetes-the-hard-way)
- [Cilium Documentation](https://docs.cilium.io/)
- [Cilium IPv6 Guide](https://docs.cilium.io/en/stable/network/concepts/ipv6/)

