Perfect 👍 — here’s a **complete, production-style verification and testing guide** for your **Cluster Autoscaler** (specific to your EKS setup with Terraform, Helm, and Pod Identity).

You can save this as `docs/verify-cluster-autoscaler.md` in your repo if you’d like — it’s written for operational reference.

---

# ✅ Verifying & Testing Cluster Autoscaler on EKS

This guide helps you confirm that the **Cluster Autoscaler** deployed via Terraform is:

* Installed correctly
* Authenticated using Pod Identity
* Able to scale your node groups **up and down automatically**

---

## 🧩 Step 1 — Check Deployment Status

Run:

```bash
kubectl -n kube-system get pods -l app.kubernetes.io/name=aws-cluster-autoscaler
```

✅ Expected output:

```
NAME                                                       READY   STATUS    RESTARTS   AGE
cluster-autoscaler-aws-cluster-autoscaler-7f758f47fc-hnrlz 1/1     Running   0          5m
```

If you see `Running (1/1)` — the pod is healthy and active.

Also confirm Helm installed it properly:

```bash
helm list -n kube-system
```

✅ You should see:

```
cluster-autoscaler   kube-system   deployed   cluster-autoscaler-<version>
```

---

## 🔍 Step 2 — Check Logs

Cluster Autoscaler logs confirm that it’s connected to the right cluster and node groups.

```bash
kubectl -n kube-system logs -l app.kubernetes.io/name=aws-cluster-autoscaler --tail=50
```

✅ Look for messages like:

```
I... Cluster-autoscaler running on AWS
I... Registered ASG: eks-test-cluster:nodegroup/general
I... No unschedulable pods
```

If you see errors like `AccessDenied` or `Failed to discover ASGs`, check the IAM role or Pod Identity association.

---

## 🔐 Step 3 — Verify IAM Role / Pod Identity Association

Confirm that Pod Identity is linked correctly:

```bash
aws eks list-pod-identity-associations --cluster-name eks-test-cluster
```

✅ You should see something like:

```json
{
  "associations": [
    {
      "associationArn": "arn:aws:eks:eu-central-2:123456789012:podidentityassociation/cluster-autoscaler",
      "roleArn": "arn:aws:iam::123456789012:role/eks-test-cluster-cluster-autoscaler-role",
      "namespace": "kube-system",
      "serviceAccount": "cluster-autoscaler"
    }
  ]
}
```

And verify that your ServiceAccount in Kubernetes has the annotation:

```bash
kubectl -n kube-system get sa cluster-autoscaler -o yaml | grep role-arn
```

✅ Expected:

```
eks.amazonaws.com/role-arn: arn:aws:iam::<ACCOUNT_ID>:role/eks-test-cluster-cluster-autoscaler-role
```

---

## ⚙️ Step 4 — Test Automatic Scaling (Scale Up)

Deploy a test workload that exceeds your cluster’s current capacity.

```bash
kubectl create deployment scale-test --image=nginx --replicas=20
```

Then watch the pods:

```bash
kubectl get pods -w
```

At first, several pods will show:

```
Pending   (0/1 nodes available)
```

After a few minutes, Cluster Autoscaler will detect pending pods and request new nodes from your node group.
You can watch this happening live in logs:

```bash
kubectl -n kube-system logs -l app.kubernetes.io/name=aws-cluster-autoscaler -f
```

Look for:

```
I... Scale-up: group eks-test-cluster:nodegroup/general increased from 2 to 4
```

Then confirm new nodes joined:

```bash
kubectl get nodes
```

✅ You’ll see more nodes than before (e.g., from 2 → 4).

---

## 🧹 Step 5 — Test Scale Down

Delete the test deployment:

```bash
kubectl delete deployment scale-test
```

Wait about 10–15 minutes (depending on your autoscaler’s configuration).
Cluster Autoscaler should remove unused nodes automatically.

Watch for log messages like:

```
I... Scale-down: removing node ip-10-1-128-42.eu-central-2.compute.internal
```

Then confirm:

```bash
kubectl get nodes
```

✅ Node count returns to the original desired size (e.g., 4 → 2).

---

## 🧰 Step 6 — Optional: View Metrics & Status

If you installed the **Metrics Server** (as you did earlier), you can view scaling metrics:

```bash
kubectl top nodes
kubectl top pods -A
```

And inspect Cluster Autoscaler config:

```bash
kubectl -n kube-system describe deployment cluster-autoscaler-aws-cluster-autoscaler
```

---

## 🧾 Troubleshooting Quick Reference

| Symptom                  | Likely Cause                              | Fix                                                                                                        |
| ------------------------ | ----------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| Pod not found            | Helm release failed or namespace mismatch | Check `helm list -n kube-system`                                                                           |
| Pod Pending              | NodeGroup IAM role / permissions issue    | Check PodIdentity and IAM trust policy                                                                     |
| Scale-up doesn’t happen  | Node group not tagged properly            | Ensure tags: `k8s.io/cluster-autoscaler/enabled=true` and `k8s.io/cluster-autoscaler/<cluster-name>=owned` |
| Scale-down not triggered | Idle timeout not reached                  | Wait 10–15 min or reduce `--scale-down-delay-after-delete`                                                 |
| AccessDenied in logs     | Wrong or missing IAM role                 | Check role trust and Pod Identity link                                                                     |

---

## ✅ Summary

You’ve verified that:

* The **Helm release** is deployed and healthy.
* The **Pod Identity association** is valid and used.
* Cluster Autoscaler successfully scales **up** and **down** automatically.

At this point, your EKS cluster is fully **self-adjusting**, saving costs while handling variable workloads dynamically.

---

Would you like me to add this as a **markdown file (`docs/verify-cluster-autoscaler.md`)** ready for Confluence (with formatted code and emoji headings like your other guides)?
