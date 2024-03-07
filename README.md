# Smile Interview Submission


### API SPECIFICATION

The application endpoints:

* `/`
  * Accepts GET requests.
  * Returns a json body response
  * Example use:

    ```bash
    curl 127.0.0.1:8080
    ```
  * Example response:

    ```json
    {"message": "Hello Smile"}
    ```


    
* `/healthy`
  * Accepts a GET request
  * Returns 200 if the application is ready.
  * Returns 500 if the application is not ready
  * Example use:

    ```bash
    curl 127.0.0.1:8080/healthy
    ```


## INFRASTRUCTURE 

The App is packaged as a docker image and can be deployed on kubernetes. The basic manifests required to deploy the application to a kubernetes cluster are provided in the `k8s` folder

```
    └── k8s   
        ├── deployment.yaml
        ├── svc.yaml
        ├── hpa.yaml
        ├── namespace.yaml
        └── sa.yaml
```
####  Kubernetes Resources deployed
1. `ServiceAccount`
2. `Deployment`
3. `Service`
4. `HorizontalPodAutoscaler`
5. `Namespace`

#### AWS Resources deployed
1. `VPC|Subnets|NatGateways`
2. `EKS Cluster`
3. `ECR Repository`
4. `IAM Resources`


## Production

### Deployment Steps

*NOTE*: Terraform state is stored locally !! 

 ##### Requirements
  * `Docker` with [Compose](https://docs.docker.com/compose/)
  * `Terraform`
  * `AWS cli`
  * `yq`

**Tip**: Use the helper script to run all deployment steps with 1 command. You must first set environment variables in step 1.

By default the script will use `IMAGE_TAG=1.0.0` , to use a different tag run  `export IMAGE_TAG=<preferred tag>` first.

```sh
 ./helper.sh k8s-deploy
```


#### Individual Steps


 1. Set up AWS credentials. You can read how [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-authentication.html)

    Recommended that you use the option of setting environment variables for this demo

    ```sh
    export AWS_SECRET_ACCESS_KEY=<Actual Secret Access Key>
    export AWS_ACCESS_KEY_ID=<Actual Access Key> 
    export TF_VAR_aws_region=<Actual AWS Region> 
    ```

 2. Change directory to the `terraform` folder

    ```sh
    cd terraform
    ```
 
 3. Initialize Terraform configuration by using the command below
 
    ```sh
    terraform init 
    ```

 4. Plan Terraform configuration by using the command below
 
    ```sh
    terraform plan
    ```

 5. Apply Terraform configuration by using the command below
 
    ```sh
    terraform apply 
    ```

    Confirm the planned changes by entering `yes`

    ```sh
    Do you want to perform these actions?
    Terraform will perform the actions described above.
    Only 'yes' will be accepted to approve.

    Enter a value: yes
    ```
  
 6. Set the IMAGE environment variable 
    ```sh
    export IMAGE_REPO=$(terraform output  -raw container_repository)
    export IMAGE_REGISTRY=$(echo ${IMAGE_REPO}| cut -d '/' -f1)
    export IMAGE_TAG=1.0.0
    export IMAGE=$IMAGE_REPO:$IMAGE_TAG
    ```

 7. Build and Push image to container registry
  
    ```sh
    # change directory
    cd ../

    # build image
    docker build -t simple-app:$IMAGE_TAG .

    # tag image
    docker tag simple-app:$IMAGE_TAG $IMAGE

    # login to image registry 
    aws ecr get-login-password --region $TF_VAR_aws_region | docker login --username AWS --password-stdin $IMAGE_REGISTRY


    # push image to registry
    docker push $IMAGE
    
    ```

 8. Deploy kubernetes manifests
    ```sh

    # set image and tag in mainifest
    yq e -i '.spec.template.spec.containers[0].image=env(IMAGE)' k8s/deployment.yaml

    # set kube context
    aws eks update-kubeconfig --region $TF_VAR_aws_region --name main --alias main 

    # apply manifests
    kubectl apply -f k8s/      
    
    ```


### Cleanup Steps

Tip: Use helper script to run all cleanup steps with 1 command.
```sh
 ./helper.sh k8s-clean
```

#### Individual Steps

1.  Follow the steps below to cleanup the created resources

    ```sh
    # delete kubernetes resources
    kubectl delete -f k8s/ 
    
    # Force delete ECR Repository using aws cli. (Terraform cannot force delete because the repository is not empty)
    aws ecr delete-repository --repository-name simple-app --force --region $TF_VAR_aws_region

    # Destroy terraform resources
    cd terraform

    terraform destroy
    ```

 2.  Confirm that you want to delete the resources
  
      ```sh
      Do you really want to destroy all resources?
      Terraform will destroy all your managed infrastructure, as shown above.
      There is no undo. Only 'yes' will be accepted to confirm.

      Enter a value: yes
      ```
    
## Local Deployments
###  1. <u> Deploying as a local docker container </u>

 ##### Requirements
* `Docker` with [Compose](https://docs.docker.com/compose/)
*  Port (8080)


To deploy as a local docker container you can use the helper script provided by running the below command in the project root directory

```
 ./helper.sh run
 ```

The script will do the following: 

1. Builds the docker image with tag `simple-app:latest`
2. Runs a local container with the image
3. Exposes the container for local network traffic on port `8080`


Access the application on [http://localhost:8080](http://localhost:8080)

You can clean up the local docker container by running 

```
./helper.sh clean
```

###  1. <u> Running locally in debug mode </u>

 ##### Requirements
* `Python3`
*  Port (8080)


To run the app locally in debug mode you can use the helper script provided by running the below command in the project root directory

```sh
 ./helper.sh debug
 ```

The script will do the following: 

1. Runs the python app locally on port 8080

Access the application on [http://localhost:8080](http://localhost:8080)


    
### Road Map
 Some features that should be implemented in the future
  
 - Add Node Autoscaling Capability to the cluster (Karpenter, Cluster Autoscaler)
 - Implement a Service Mesh
 - Observability Dashboard for monitoring resources in the cluster
 - Policy As Code Tooling (OPA, Kyverno)
 - Implement Topology Spread Strategy for Nodes across Multiple AZs
 - Deploy an Ingress Controller (Possible use Mesh Gateway)