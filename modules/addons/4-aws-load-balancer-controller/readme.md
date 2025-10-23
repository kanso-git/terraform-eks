To verify that the **AWS Load Balancer Controller (LBC)** is installed and running correctly in your Kubernetes cluster, you can perform several checks — from Helm/Kubernetes resources to logs and AWS integration.

Here’s a step-by-step guide 👇

---

### 🧩 1. **Check Helm Release (if installed via Helm)**

If you installed the AWS Load Balancer Controller with Helm:

```bash
helm list -n kube-system
```

Look for a release named something like:

```
aws-load-balancer-controller
```

To inspect details:

```bash
helm status aws-load-balancer-controller -n kube-system
```

This shows status, version, and deployment health.

---

### 🔍 2. **Check Deployment in the Cluster**

Run:

```bash
kubectl get deployment -n kube-system
```

You should see something like:

```
NAME                                           READY   UP-TO-DATE   AVAILABLE   AGE
aws-load-balancer-controller                   1/1     1            1           2d
```

✅ `READY` should show `1/1` (or the number of replicas you deployed).

To get more details:

```bash
kubectl describe deployment aws-load-balancer-controller -n kube-system
```

---

### 🧠 3. **Check Pods**

List pods in the `kube-system` namespace:

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

You should see something like:

```
aws-load-balancer-controller-7d8b66b5f9-h4m6n   1/1     Running   0          2d
```

If pods are not running, view logs for clues:

```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```

---

### 🧾 4. **Confirm CRDs Installed**

The LBC installs Custom Resource Definitions (CRDs) for ingress and target groups. Check them:

```bash
kubectl get crds | grep aws
```

You should see entries like:

```
targetgroupbindings.elbv2.k8s.aws
```

---

### 🌐 5. **Check Controller Version**

You can check the running image version:

```bash
kubectl -n kube-system get deployment aws-load-balancer-controller -o=jsonpath='{.spec.template.spec.containers[0].image}'
```

Example output:

```
602401143452.dkr.ecr.us-west-2.amazonaws.com/amazon/aws-load-balancer-controller:v2.8.2
```

---

### 🧭 6. **Verify Controller Functionality**

Try to describe an ingress resource managed by the controller:

```bash
kubectl describe ingress <your-ingress-name> -n <namespace>
```

You should see annotations like:

```
kubernetes.io/ingress.class: alb
```

and the controller should automatically create an AWS ALB visible in your **AWS Console → EC2 → Load Balancers**.

---

### 🪵 7. **Check Controller Logs for Health**

You can directly inspect logs:

```bash
kubectl logs -n kube-system deploy/aws-load-balancer-controller
```

Look for:

```
Successfully started AWS Load Balancer controller
```

or log messages showing reconciliation of Ingresses and TargetGroupBindings.

---

### ✅ Summary Table

| Check        | Command                                                                                  | Expected Output                                 |                                     |
| ------------ | ---------------------------------------------------------------------------------------- | ----------------------------------------------- | ----------------------------------- |
| Helm release | `helm list -n kube-system`                                                               | `aws-load-balancer-controller` present          |                                     |
| Deployment   | `kubectl get deployment -n kube-system`                                                  | READY column = `1/1`                            |                                     |
| Pods         | `kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller` | Status = `Running`                              |                                     |
| CRDs         | `kubectl get crds                                                                        | grep aws`                                       | `targetgroupbindings.elbv2.k8s.aws` |
| Version      | `kubectl get deployment ... -o=jsonpath='{.spec.template.spec.containers[0].image}'`     | Valid AWS LBC image tag                         |                                     |
| Logs         | `kubectl logs -n kube-system deploy/aws-load-balancer-controller`                        | Startup success message                         |                                     |
| ALB creation | `kubectl describe ingress <name>`                                                        | ALB-related annotations and external DNS in AWS |                                     |

---

Would you like me to give you a **single “quick verification” script** (a one-liner that summarizes these checks automatically)?
