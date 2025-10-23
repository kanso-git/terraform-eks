Check that the addon is active:
k get daemonset eks-pod-identity-agent -n kube-system
 or  
aws eks list-addons --cluster-name eks-test-cluster --region eu-central-2

You should see:

{
  "addons": [
    "vpc-cni",
    "coredns",
    "kube-proxy",
    "eks-pod-identity-agent"
  ]
}


And verify the deployment in Kubernetes:

kubectl get pods -n kube-system | grep pod-identity


You should see pods like:

eks-pod-identity-agent-xxxxx   Running
eks-pod-identity-agent-yyyyy   Running