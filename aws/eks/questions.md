# Questions for EKS

## Theory Questions
1. What are the main components of Amazon EKS and how do they differ from a self‑managed Kubernetes cluster?
2. Explain the role of the EKS control plane and how AWS manages its availability and upgrades.
3. How does IAM integration work with EKS for pod‑level permissions (IRSA)?
4. What are the networking options for EKS (Amazon VPC CNI, kube‑proxy, etc.) and their trade‑offs?
5. Describe how EKS add‑ons (e.g., CoreDNS, kube‑proxy, AWS‑load‑balancer‑controller) are managed and upgraded.

## Practical Scenarios
1. A newly created EKS node group cannot join the cluster because the security group is misconfigured. Walk through the debugging steps.
2. Pods are failing to pull images from a private ECR repository. Explain how to configure IAM roles for service accounts to resolve this.
3. You need to perform a rolling upgrade of the Kubernetes version across the control plane and node groups with zero downtime. Outline the required steps.
4. An application experiences intermittent connectivity issues due to IP address exhaustion. Show how to troubleshoot the VPC CNI plugin.
5. Configure a horizontal pod autoscaler that scales based on custom CloudWatch metrics for a microservice running on EKS.
