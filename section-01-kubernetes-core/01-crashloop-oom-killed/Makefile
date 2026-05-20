.PHONY: deploy describe logs watch clean fix verify

# Deploy the broken scenario
deploy:
	kubectl apply -f deployment.yaml

# Show pod status and events
describe:
	@POD=$$(kubectl get pods -l app=oom-demo -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
	if [ -n "$$POD" ]; then \
		echo "=== Pod Status ==="; \
		kubectl get pod $$POD; \
		echo; \
		echo "=== Last State (scroll to find OOMKilled) ==="; \
		kubectl describe pod $$POD | grep -A 10 "Last State"; \
	else \
		echo "Pod not found. Deploy with: make deploy"; \
	fi

# Stream logs from the pod
logs:
	@POD=$$(kubectl get pods -l app=oom-demo -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
	if [ -n "$$POD" ]; then \
		kubectl logs $$POD; \
	else \
		echo "Pod not found. Deploy with: make deploy"; \
	fi

# Watch pods in real-time
watch:
	kubectl get pods -l app=oom-demo -w

# Apply the fix (increase memory limit)
fix:
	@echo "Editing deployment.yaml to fix memory limit..."
	sed -i 's/memory: "64Mi"/memory: "256Mi"/g' deployment.yaml
	sed -i '26s/memory: "32Mi"/memory: "64Mi"/' deployment.yaml
	@echo "Applying fix..."
	kubectl apply -f deployment.yaml
	@echo "Fixed! Pod should be Running now."

# Verify the fix worked
verify:
	@POD=$$(kubectl get pods -l app=oom-demo -o jsonpath='{.items[0].metadata.name}' 2>/dev/null); \
	if [ -n "$$POD" ]; then \
		STATUS=$$(kubectl get pod $$POD -o jsonpath='{.status.phase}'); \
		if [ "$$STATUS" = "Running" ]; then \
			echo "✅ Pod is Running!"; \
			echo; \
			echo "=== Logs (should show successful allocation) ==="; \
			kubectl logs $$POD | tail -5; \
		else \
			echo "❌ Pod is still $$STATUS"; \
			make describe; \
		fi \
	else \
		echo "Pod not found. Deploy with: make deploy"; \
	fi

# Delete the deployment
clean:
	kubectl delete deployment oom-demo

# Full cycle: deploy, debug, fix, verify
demo: deploy
	@echo "1. Deployment applied - Pod should be in CrashLoopBackOff"
	@sleep 3
	@make watch &
	@sleep 10
	@echo; echo "2. Running describe to show the issue..."
	@make describe
	@echo; echo "3. Fixing deployment.yaml..."
	@make fix
	@sleep 3
	@echo; echo "4. Verifying the fix..."
	@make verify
