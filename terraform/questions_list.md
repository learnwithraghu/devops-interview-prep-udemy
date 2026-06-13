# Terraform Interview Questions

## Theory Questions
1. What is Terraform, and how does it compare to configuration management tools like Ansible?
2. Explain the purpose of the Terraform state file (`terraform.tfstate`).
3. What are Terraform modules, and why are they used?
4. How does Terraform handle dependencies between resources?
5. Explain the difference between `terraform plan` and `terraform apply`.

## Practical Scenarios
6. **Scenario:** Your team member manually deleted an EC2 instance created by Terraform via the AWS console. What happens on the next `terraform apply`, and how do you resolve the drift?
7. **Scenario:** You need to securely pass API keys into your Terraform code. How do you achieve this?
8. **Scenario:** A deployment failed halfway through, leaving the state file locked. How do you recover?
9. **Scenario:** You are refactoring a monolithic Terraform configuration into modules. How do you move existing resources without destroying and recreating them?
10. **Scenario:** Two engineers try to run `terraform apply` concurrently. How does Terraform prevent conflicts, and how do you configure it?
