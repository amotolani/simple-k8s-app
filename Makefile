.PHONY: k8s-deploy
k8s-deploy: check-env deploy

.PHONY: deploy
deploy: check-env
	cd terraform && terraform init && terraform plan && terraform apply -auto-approve && terraform output -raw container_repository > ../.tmp_ecr
	$(eval IMAGE_REPO = $(shell cat .tmp_ecr))
	$(eval IMAGE_REGISTRY = $(shell echo $(IMAGE_REPO)| cut -d '/' -f1))
	$(eval IMAGE_TAG ?= 1.0.0 )
	$(eval IMAGE = $(IMAGE_REPO):$(IMAGE_TAG))
	docker build -t simple-app:$(IMAGE_TAG) .
	docker tag simple-app:$(IMAGE_TAG) $(IMAGE) 
	aws ecr get-login-password --region $(TF_VAR_aws_region) | docker login --username AWS --password-stdin $(IMAGE_REGISTRY)
	docker push $(IMAGE) 
	yq e -i '.spec.template.spec.containers[0].image="$(IMAGE)"' k8s/deployment.yaml
	aws eks update-kubeconfig --region $(TF_VAR_aws_region) --name main --alias main
	kubectl apply -f k8s/namespace.yaml && sleep 3
	kubectl apply -f k8s/
	# rm .tmp_ecr

.PHONY: check-env
check-env:
ifndef TF_VAR_aws_region
	$(error TF_VAR_aws_region is not set)
endif
ifndef AWS_SECRET_ACCESS_KEY
	$(error AWS_SECRET_ACCESS_KEY is not set)
endif
ifndef AWS_ACCESS_KEY_ID
	$(error AWS_ACCESS_KEY_ID is not set)
endif
ifndef IMAGE_TAG
	@echo "IMAGE_TAG not set. Using IMAGE_TAG=1.0.0"
endif
	@echo "AWS environment variables are set. Running deployment..."



.PHONY: k8s-clean
k8s-clean: check-env
	kubectl delete -f k8s/
	aws ecr delete-repository --repository-name simple-app --force --region $(TF_VAR_aws_region) --output json
	cd terraform && terraform apply -destroy -auto-approve


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
