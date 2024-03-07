#!/bin/bash

# Check if required environment variables are set
check_env() {
    if [[ -z "$TF_VAR_aws_region" ]]; then
        echo "TF_VAR_aws_region is not set"
        exit 1
    fi

    if [[ -z "$AWS_SECRET_ACCESS_KEY" ]]; then
        echo "AWS_SECRET_ACCESS_KEY is not set"
        exit 1
    fi

    if [[ -z "$AWS_ACCESS_KEY_ID" ]]; then
        echo "AWS_ACCESS_KEY_ID is not set"
        exit 1
    fi

    if [[ -z "$IMAGE_TAG" ]]; then
        echo "IMAGE_TAG not set. Using IMAGE_TAG=1.0.0"
    fi

    echo "AWS environment variables are set. Running deployment..."
}

# Deploy Kubernetes resources
deploy_k8s() {
    cd terraform || exit
    terraform init
    terraform plan
    terraform apply -auto-approve
    IMAGE_REPO=$(terraform output -raw container_repository)
    IMAGE_REGISTRY=$(echo "$IMAGE_REPO" | cut -d'/' -f1)
    IMAGE_TAG=${IMAGE_TAG:-"1.0.0"}
    IMAGE="$IMAGE_REPO:$IMAGE_TAG"
    cd ../ || exit
    docker build -t simple-app:"$IMAGE_TAG" .
    docker tag simple-app:"$IMAGE_TAG" "$IMAGE"
    aws ecr get-login-password --region "$TF_VAR_aws_region" | docker login --username AWS --password-stdin "$IMAGE_REGISTRY"
    docker push "$IMAGE"
    yq e -i '.spec.template.spec.containers[0].image="'$IMAGE'"' k8s/deployment.yaml
    aws eks update-kubeconfig --region "$TF_VAR_aws_region" --name main --alias main
    kubectl apply -f k8s/namespace.yaml && sleep 3
    kubectl apply -f k8s/
    # rm .tmp_ecr
}

# Cleanup Kubernetes resources
clean_k8s() {
    kubectl delete -f k8s/
    aws ecr delete-repository --repository-name simple-app --force --region "$TF_VAR_aws_region" --output json
    cd terraform || exit
    terraform apply -destroy -auto-approve
}

# Deploy as local container
run() {
    docker compose up -d
}

# cleanup local container
clean(){
	docker compose down 
	docker image rm simple-app:latest 
}

debug(){
    python3 -m pip install -r requirements.txt
    python3 app.py 
}
	

# Main function
main() {
    case $1 in
        k8s-deploy)
            check_env
            deploy_k8s
            ;;
        k8s-clean)
            check_env
            clean_k8s
            ;;
        run)
            run
            ;;
        clean)
            clean
            ;;
        debug)
            debug
            ;;
        *)
            echo "Usage: $0 {k8s-deploy|k8s-clean|run|clean|debug}"
            exit 1
            ;;
    esac
}

main "$@"