# Nginx Interview Questions — DevOps / SRE Focus

## Theory Questions

1. What is Nginx, and what is the difference between using it as a **web server** vs a **reverse proxy** vs a **load balancer**?
2. Explain the Nginx **worker process model**. How does it handle concurrent connections differently from Apache?
3. What is the difference between `proxy_pass` and `try_files` in an Nginx config block?
4. How does Nginx decide which `server` block to use when multiple virtual hosts are configured? What is the role of `server_name` and the default server?
5. What are Nginx **upstream groups**, and how do you configure different load balancing algorithms (round-robin, least connections, ip_hash)?
6. What is the difference between `location /` and `location ^~ /api/` and `location ~ \.php$`? How does Nginx evaluate `location` priority?
7. How do you configure SSL/TLS termination in Nginx? What directives control the certificate, key, and minimum TLS version?
8. What is `proxy_cache` in Nginx and how would an SRE use it to reduce load on an upstream service?
9. How do you implement **rate limiting** in Nginx using `limit_req_zone` and `limit_req`? What happens to requests that exceed the limit?
10. How do you perform a **zero-downtime reload** of an Nginx configuration, and how is this different from a full restart?

## Practical Scenarios

11. **Scenario:** A new Nginx deployment is returning 502 Bad Gateway for all API requests. The upstream application is running and healthy on port 8080. What do you check first?
12. **Scenario:** Your Nginx reverse proxy is adding latency to API responses. You want to enable response caching for `GET` requests only. How do you configure this?
13. **Scenario:** A service behind Nginx is getting hammered by a bot sending thousands of requests per second. You need to add rate limiting without disrupting legitimate users. Walk me through the config.
14. **Scenario:** You need to configure Nginx to serve your React SPA (single-page app) so that deep-linked URLs like `/dashboard/settings` work correctly and don't return 404. How do you fix the `location` block?
15. **Scenario:** After deploying a new `nginx.conf`, all traffic to the server dropped. How do you safely validate and roll back an Nginx configuration?
