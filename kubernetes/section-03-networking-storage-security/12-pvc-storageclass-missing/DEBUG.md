# Debugging Guide: PVC Stuck Pending

## Quick Start Checklist

- [ ] Cluster running on EC2: `kubectl get nodes`
- [ ] Image built: `docker images | grep k8s-debug-app`
- [ ] Manifest deployed: `kubectl apply -f deployment.yaml`
- [ ] Ready to debug: PVC shows `Pending`, Pod shows `Pending`

---

## Step 1: Observe the Broken State

### Deploy the broken version:
```bash
cd section-03-networking-storage-security/12-pvc-storageclass-missing
kubectl apply -f deployment.yaml
```

### Check the PVC and Pod status:
```bash
kubectl get pvc
kubectl get pods
```

**Expected output:**
```
NAME            STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-demo-data   Pending                                      fast-ssd       15s

NAME                        READY   STATUS    RESTARTS   AGE
pvc-demo-xxxxx              0/1     Pending   0          15s
```

Both the PVC and the Pod are stuck in `Pending`.

---

## Step 2: Describe the PVC

### Read PVC events:
```bash
kubectl describe pvc pvc-demo-data
```

**Expected output (Events section):**
```
Events:
  Type     Reason              Age   From                         Message
  ----     ------              ----  ----                         -------
  Warning  ProvisioningFailed  30s   persistentvolume-controller  storageclass.storage.k8s.io "fast-ssd" not found
```

This tells us the StorageClass `fast-ssd` does not exist in the cluster. The PVC cannot be provisioned.

---

## Step 3: List Available StorageClasses

### See what StorageClasses the cluster actually has:
```bash
kubectl get storageclass
```

**Expected output:**
```
NAME                 PROVISIONER             RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
standard (default)   rancher.io/local-path   Delete          WaitForFirstConsumer   false                  5m
```

The kind cluster has `standard` as the default StorageClass. There is no `fast-ssd`.

---

## Root Cause Analysis

By now you've seen:
- PVC `pvc-demo-data` is stuck in `Pending`
- `describe pvc` shows `storageclass.storage.k8s.io "fast-ssd" not found`
- `kubectl get storageclass` shows only `standard` exists

**What happens:**
1. The manifest requests a PVC with `storageClassName: fast-ssd`
2. Kubernetes looks for a StorageClass named `fast-ssd`
3. No such StorageClass exists → provisioning fails
4. The PVC stays `Pending`
5. The Deployment Pod references the PVC in a volumeMount
6. The Pod cannot schedule until the PVC is bound → Pod stays `Pending`

---

## The Fix: Correct the StorageClass Name

### Edit deployment.yaml:
```bash
vim deployment.yaml
```

1. Search for the PVC section: `/PersistentVolumeClaim`
2. Navigate to the storageClassName line:
   ```yaml
     storageClassName: fast-ssd     # <-- EDIT THIS LINE: change to standard
   ```
3. Press `i` to enter insert mode
4. Change `fast-ssd` to `standard`
5. Press `Esc` then save: `:wq`

Verify the PVC section now looks like this:
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-demo-data
  labels:
    app: pvc-demo
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: standard
  resources:
    requests:
      storage: 1Gi
```

---

## Step 4: Apply and Verify

If the PVC already exists from the broken deploy, delete it first — `storageClassName` cannot be changed on an existing PVC:

```bash
kubectl delete deployment pvc-demo
kubectl delete pvc pvc-demo-data
```

### Apply the fixed manifest:
```bash
kubectl apply -f deployment.yaml
```

### Verify the PVC is bound:
```bash
kubectl get pvc
```

**Expected output:**
```
NAME            STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
pvc-demo-data   Bound    pvc-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx   1Gi        RWO            standard       2m
```

### Verify the Pod is running:
```bash
kubectl get pods
```

**Expected output:**
```
NAME                        READY   STATUS    RESTARTS   AGE
pvc-demo-xxxxx              1/1     Running   0          10s
```

Success! The PVC bound to a dynamically provisioned volume and the Pod mounted it.

---

## Instructor Talking Points

### 1. PVC Events Tell You Everything
"When a PVC is stuck in Pending, `kubectl describe pvc` is your first command. The Events section almost always tells you exactly why — StorageClass not found, no matching PV, insufficient storage, or quota exceeded. Don't guess; read the events."

### 2. StorageClass Is the Link to Provisioning
"A StorageClass defines how persistent storage is dynamically provisioned. When you set `storageClassName` on a PVC, Kubernetes uses that class's provisioner to create a PersistentVolume. If the name is wrong, nothing happens — the PVC waits forever."

### 3. Pod Pending Can Be a Storage Problem
"Students often start debugging a Pending Pod with node affinity or resource limits. But if the Pod mounts a PVC, check the PVC first. An unbound PVC blocks Pod scheduling entirely. Always run `kubectl get pvc` when you see a Pending Pod with volumes."

### 4. kind Uses local-path Provisioner
"On the EC2 kind cluster, the default StorageClass `standard` uses the local-path provisioner. It creates volumes on the node's local disk. This is fine for training — in production you'd use EBS, EFS, or another cloud storage class."

---

## Cleanup

To remove all resources:
```bash
kubectl delete -f deployment.yaml
```

Or move on to the next scenario.
