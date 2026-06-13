# Postman Interview Questions — DevOps / SRE Focus

## Theory Questions

1. What is a Postman Collection and how would a DevOps engineer use it beyond just manual API exploration?
2. What is Newman, and how do you integrate Postman collections into a CI/CD pipeline to gate deployments?
3. Explain the difference between Postman **Environments**, **Global Variables**, and **Collection Variables**. When would you use each?
4. What are **Pre-request Scripts** in Postman, and give a real-world DevOps example of why they are needed (e.g., token refresh).
5. What is **contract testing**, and how does Postman's test scripting support it compared to tools like Pact?

## Practical Scenarios

6. **Scenario:** You deployed a new service and want to write a Postman health check collection that validates the status code, response time, and JSON shape. How do you set this up and run it automatically?

7. **Scenario:** Your Postman collection runs perfectly in the "dev" environment but every request fails with 404 in "staging". What do you investigate first?

8. **Scenario:** A Postman collection that calls a protected API starts failing overnight with 401 Unauthorized errors, even though the correct credentials are configured. Walk me through debugging and fixing this.

9. **Scenario:** You want to add a Postman collection run as a quality gate in your CI/CD pipeline so the deployment fails automatically if any API test fails. How do you do this using Newman?

10. **Scenario:** An upstream team updated their API without telling your team. Your service breaks in production. How could you have caught this earlier using Postman contract tests?
