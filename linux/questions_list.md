# Linux Interview Questions

## Theory Questions
1. What happens during the Linux boot process (from BIOS to init/systemd)?
2. Explain the concepts of inodes, hard links, and soft links.
3. What is the difference between TCP and UDP? Give an example use case for each.
4. Explain file permissions in Linux (read, write, execute) and how to change them (chmod, chown).
5. What are namespaces and cgroups in Linux, and how do they relate to containers?

## Practical Scenarios
6. **Scenario:** A server is experiencing high load average, but CPU usage is low. What could be causing this, and which tools would you use to investigate? (Hint: Disk I/O or network wait).
7. **Scenario:** An application cannot bind to port 80 because it says the port is already in use. How do you find the process using the port and kill it?
8. **Scenario:** You accidentally deleted an important log file while a process was still writing to it. Can you recover it? If so, how?
9. **Scenario:** The filesystem is showing 100% full, but `du -sh *` shows plenty of free space. What is the likely cause and how do you fix it?
10. **Scenario:** You need to securely transfer a large directory to a remote server over an unstable network. Which tool would you use and what flags?
