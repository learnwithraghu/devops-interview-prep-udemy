# Kubernetes Interview Questions

## Theory Questions
1. Explain the Kubernetes architecture (Control Plane and Worker Nodes).
2. What is a Pod, and why does Kubernetes use Pods instead of running containers directly?
3. How does a Kubernetes Service work, and what are the different types of Services?
4. Explain the difference between a Deployment and a StatefulSet.
5. What are Ingress controllers and how do they route traffic?

## Practical Scenarios
6. **Scenario:** A Pod is stuck in `CrashLoopBackOff`. Walk me through the steps you would take to find the root cause. (See `practical/section-01-kubernetes-core/01-crashloop-oom-killed/` for practice)
7. **Scenario:** A Pod is stuck in `Pending` state. What are the common causes and how do you investigate?
8. **Scenario:** You applied a NetworkPolicy to restrict traffic, but now legitimate traffic is being blocked. How do you debug it?
9. **Scenario:** Users are reporting 502 Bad Gateway errors when accessing an application via Ingress. How do you trace the request flow to find the issue?
10. **Scenario:** Your HPA (Horizontal Pod Autoscaler) is not scaling up the deployment despite high CPU usage. What could be wrong?
