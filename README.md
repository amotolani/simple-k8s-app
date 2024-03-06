# Skills Interview Submission

## Deployment Instructions

The App packaged as a docker image and can be deployed on kubernetes. The basic manifests required to deploy the application to a kubernetes cluster are provided in the `kubernetes` folder

```
 └──kubernetes
    └── manifests       # contains files to deploy the app to the k8s cluster as a deployment with 2 replicas
        ├── deployment.yaml
        ├── service.yaml
        └── service_account.yaml
```
### Application Resources deployed
1. `ServiceAccount`
2. `Deployment`. Deployment manifest with 3 replicas
3. `Service`. Service to expose the application



## Production Deployment 
###  1. <u> Creating  AWS Infrastructure </u>

*NOTE*: Terraform state is stored locally !! 


 1. Set up AWS credentials. You can read how [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-authentication.html)

    Recommended that you use the option of setting environment variables for this demo

    ```
    export AWS_SECRET_ACCESS_KEY=<Actual Secret Access Key>
    export AWS_ACCESS_KEY_ID=<Actual Access Key>  
    ```

 2. Change directory to the `terraform` folder

    ```sh
    cd terraform
    ```
 
 3. Init Terraform configuration by using the command below
 
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
    export IMAGE_REPO=$(terraform output  -raw container-registry)
    export IMAGE_REGISTRY=${IMAGE_REPO%/*}
    export IMAGE_TAG=0.0.1
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
    aws ecr get-login-password --region us-east-2 | docker login --username AWS --password-stdin $IMAGE_REGISTRY


    # push image to registry
    docker push $IMAGE
    
    ```

 8. Deploy kubernetes manifests
    ```sh

    # set image and tag in mainifest (ran with yq=4.40.5)
    yq e -i '.spec.template.spec.containers[0].image=env(IMAGE)' k8s/deployment.yaml

    # set kube context
    aws eks update-kubeconfig --region us-east-2 --name main --alias main 

    # apply manifests
    kubectl apply -f k8s/      
    
    ```



Cleanup

```
kubectl delete -f k8s/ 
aws ecr delete-repository --repository-name simple-app --force --region us-east-2
terraform destroy
```
## Local Deployment
###  1. <u> Deploying as a local docker container </u>

 ##### Requirements
* Install `Docker`
* Free Port (8080)


To deploy as a local docker container you can use the helper script provided by running the below command in the project root directory

```
 make local-docker-run
 ```

The script will do the following: 

1. Builds the docker image with tag `simple-app:latest`
2. Runs a local container with the image
3. Exposes the container for local network traffic


Access the application on [http://localhost:8080](http://localhost:8080)

You can clean up the local docker container by running 

```
make local-docker-clean
```

### 2. <u> Deploying to local kubernetes `KIND` cluster </u>
 ##### Requirements
* Install `Kind` 
* Free Port (8080)

To deploy to a local `kind` cluster you can use the helper script provided by running the below command in the project root directory

```
 make local-k8s-run
 ```

The script will do the following: 

1. Builds the docker image with tag `simple-app:latest`
2. Creates a temporary `Kind` cluster
3. Loads the built image into the `Kind` cluster
4. Applies the kubernetes manifests into the `kind` cluster


Expose the application from the local kind cluster by running (port-forwads to local machine). 
```
make local-k8s-expose
```

Access the application on [http://localhost:8080](http://localhost:8080)

You can clean up the local kind by running 
```
make local-k8s-clean
```

### API

The application endpoints:

* `/`
  * Accepts GET requests.
  * Returns a json body response
  * Example use:

    ```bash
    curl 127.0.0.1:8080/api/files/1234
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

    
### Road Map
 Some features that should be implemented in the future
  
 - Add ability to emit application metrics. These metrics should be available on a dedicated `/metrics` endpoint
 - Add more unit and functional tests