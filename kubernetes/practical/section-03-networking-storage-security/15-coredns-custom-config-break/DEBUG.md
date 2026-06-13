# Debugging Guide: CoreDNS Custom Config Break

## Quick Start Checklist

- [ ] Cluster running on EC2: `kubectl get nodes`
- [ ] Broken ConfigMap applied: `kubectl apply -f deployment.yaml`
- [ ] CoreDNS restarted: `kubectl rollout restart deployment/coredns -n kube-system`
- [ ] Ready to debug: DNS resolution fails

---

## Step 1: Observe the Broken State

### Deploy the broken ConfigMap and restart CoreDNS:
```bash
cd section-03-networking-storage-security/15-coredns-custom-config-break
kubectl apply -f deployment.yaml
kubectl rollout restart deployment/coredns -n kube-system
kubectl rollout status deployment/coredns -n kube-system
```

### Test DNS resolution from a debug Pod:
```bash
kubectl run debug --rm -it --image=busybox --restart=Never -- nslookup kubernetes.default
```

**Expected output:**
```
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

nslookup: can't resolve 'kubernetes.default'
```

Cluster DNS is broken. Even internal service names fail to resolve.

---

## Step 2: Check CoreDNS Logs

### Find CoreDNS Pods:
```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
```

**Expected output:**
```
NAME                       READY   STATUS    RESTARTS   AGE
coredns-xxxxx              1/1     Running   0          2m
coredns-yyyyy              1/1     Running   0          2m
```

CoreDNS Pods may still show Running — a bad config does not always crash the Pod.

### Read CoreDNS logs:
```bash
kubectl logs -n kube-system -l k8s-app=kube-dns
```

**Expected output (look for timeout or forward errors):**
```
[INFO] plugin/forward: connecting to 192.0.2.1:53: dial tcp 192.0.2.1:53: i/o timeout
```

Or queries timing out without explicit errors. The logs confirm CoreDNS is forwarding to an unreachable upstream.

---

## Step 3: Inspect the CoreDNS ConfigMap

### Read the current CoreDNS configuration:
```bash
kubectl get configmap coredns -n kube-system -o yaml
```

**Expected output (Corefile section):**
```yaml
data:
  Corefile: |
    .:53 {
        errors
        health {
           lameduck 5s
        }
        ready
        forward . 192.0.2.1:53
        cache 30
        loop
        reload
        loadbalance
    }
```

Two problems:
1. The `kubernetes` plugin is **missing** — cluster-internal names like `kubernetes.default` cannot resolve
2. `forward . 192.0.2.1:53` sends all external queries to a TEST-NET address that drops traffic

Compare with the original kind CoreDNS config:
```bash
kubectl get configmap coredns -n kube-system -o yaml
```

The broken config removed the `kubernetes cluster.local ...` block and replaced `forward . /etc/resolv.conf` with a dead IP.

---

## Root Cause Analysis

By now you've seen:
- `nslookup kubernetes.default` fails from any Pod
- CoreDNS logs show forward timeouts to `192.0.2.1`
- ConfigMap is missing the `kubernetes` plugin block
- All queries forward to an unreachable upstream

**What happens:**
1. The broken ConfigMap replaces the valid Corefile
2. CoreDNS reloads the config (via `reload` plugin)
3. Internal cluster DNS queries have no `kubernetes` plugin to handle them
4. External queries forward to `192.0.2.1` which is unreachable
5. All DNS resolution fails cluster-wide

---

## The Fix: Restore the Valid Corefile

### Edit deployment.yaml:
```bash
vim deployment.yaml
```

1. Search for the Corefile: `/Corefile`
2. Replace the entire Corefile block with the corrected version below
3. Press `i` to enter insert mode, delete the broken block, and paste the fix
4. Press `Esc` then save: `:wq`

Verify the ConfigMap now looks like this:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health {
           lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        prometheus :9153
        forward . /etc/resolv.conf {
           max_concurrent 1000
        }
        cache 30
        loop
        reload
        loadbalance
    }
```

Key changes:
- **Added** the `kubernetes` plugin block for cluster-internal DNS   # <-- EDIT: restore kubernetes plugin
- **Changed** `forward . 192.0.2.1:53` to `forward . /etc/resolv.conf`   # <-- EDIT: fix forward directive

---

## Step 4: Apply and Restart CoreDNS

### Apply the fixed ConfigMap:
```bash
kubectl apply -f deployment.yaml
```

### Restart CoreDNS to pick up the change:
```bash
kubectl rollout restart deployment/coredns -n kube-system
kubectl rollout status deployment/coredns -n kube-system
```

### Verify DNS resolution works:
```bash
kubectl run debug --rm -it --image=busybox --restart=Never -- nslookup kubernetes.default
```

**Expected output:**
```
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      kubernetes.default
Address 1: 10.96.0.1 kubernetes.default.svc.cluster.local
```

### Test external DNS as well:
```bash
kubectl run debug --rm -it --image=busybox --restart=Never -- nslookup google.com
```

**Expected output:**
```
Name:      google.com
Address 1: ...
```

Success! Both internal and external DNS resolution are restored.

---

## Instructor Talking Points

### 1. CoreDNS Config Is Cluster-Critical
"A bad CoreDNS ConfigMap breaks DNS for every Pod in the cluster simultaneously. This is one of the highest-impact misconfigurations in Kubernetes. Always test DNS changes on a training cluster first, and know how to restore the original Corefile."

### 2. The kubernetes Plugin Is Non-Negotiable
"The `kubernetes` plugin handles all `*.cluster.local` and `*.svc` names. Without it, no Pod can resolve Services, the API server, or any internal hostname. If you see `kubernetes.default` failing, check whether the `kubernetes` plugin block exists in the Corefile."

### 3. forward Directive Controls External DNS
"The `forward` plugin sends queries upstream. `forward . /etc/resolv.conf` uses the node's DNS settings — the standard for kind and most clusters. Pointing it to a fixed IP like `192.0.2.1` breaks all external resolution. Always verify the forward target is reachable."

### 4. CoreDNS May Not Crash on Bad Config
"Unlike some components, CoreDNS often stays Running with a bad config — it just fails queries. Don't assume a Running Pod means healthy DNS. Test with `nslookup` from a debug Pod and read the logs."

### 5. rollout restart After ConfigMap Changes
"CoreDNS picks up ConfigMap changes via the `reload` plugin, but after a major Corefile rewrite a rollout restart is safer. Run `kubectl rollout restart deployment/coredns -n kube-system` and wait for the rollout to complete before testing."

### 6. Real-World CoreDNS Failures
"In production, CoreDNS breaks when:
- A bad `forward` directive points to a decommissioned upstream DNS server
- Custom `stubDomains` or `hosts` entries conflict with cluster DNS
- Resource limits cause CoreDNS OOMKill under query load
- A Helm chart upgrade replaces the Corefile with an incompatible version

The debugging workflow is always: test DNS from a Pod → read CoreDNS logs → inspect the ConfigMap → fix and restart."

---

## Cleanup

This scenario modifies cluster-wide DNS. After recording, ensure the fixed ConfigMap is applied and CoreDNS is healthy before proceeding to Section 4.

To verify the cluster is healthy:
```bash
kubectl run debug --rm -it --image=busybox --restart=Never -- nslookup kubernetes.default
```

Or move on to the next section.
