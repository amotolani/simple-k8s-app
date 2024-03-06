.PHONY: k8s-deploy
k8s-deploy: check-env deploy

.PHONY: deploy
deploy:
	cd terraform && terraform init && terraform plan && terraform apply -auto-approve
	export IMAGE_REPO=$$(terraform output -raw container_repository) && \
	export IMAGE_REGISTRY=$${IMAGE_REPO%/*} && \
	export IMAGE_TAG=1.0.0 && \
	export IMAGE=$$IMAGE_REPO:$$IMAGE_TAG && \
	cd .. && \
	docker build -t simple-app:$$IMAGE_TAG . && \
	docker tag simple-app:$$IMAGE_TAG $$IMAGE && \
	aws ecr get-login-password --region $(TF_VAR_AWS_REGION) | docker login --username AWS --password-stdin $$IMAGE_REGISTRY && \
	docker push $$IMAGE && \
	cd terraform && \
	yq e -i '.spec.template.spec.containers[0].image=env(IMAGE)' k8s/deployment.yaml && \
	aws eks update-kubeconfig --region $(TF_VAR_AWS_REGION) --name main --alias main && \
	kubectl apply -f k8s/

.PHONY: check-env
check-env:
ifndef TF_VAR_AWS_REGION
	$(error TF_VAR_AWS_REGION is not set)
endif
ifndef AWS_SECRET_ACCESS_KEY
	$(error AWS_SECRET_ACCESS_KEY is not set)
endif
ifndef AWS_ACCESS_KEY_ID
	$(error AWS_ACCESS_KEY_ID is not set)
endif
	@echo "AWS environment variables are set. Running deployment..."
	@echo "Using IMAGE_TAG=1.0.0"


.PHONY: k8s-clean
k8s-clean:
	kubectl delete -f k8s/
	aws ecr delete-repository --repository-name simple-app --force --region $${TF_VAR_AWS_REGION}
	cd terraform && terraform destroy


.PHONY: run
run:
	docker compose up -d


.PHONY: clean
clean:
	docker compose down 
	docker image rm simple-app:latest 

.PHONY: debug
debug:
	python3 app.py 
