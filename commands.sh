aws s3api create-bucket --bucket udacity-tf --region us-east-2 --create-bucket-configuration LocationConstraint=us-east-2
# aws s3 rm s3://udacity-tf --recursive
terraform init
terraform apply
aws eks --region us-east-2 update-kubeconfig --name udacity-cluster
kubectl config use-context arn:aws:eks:us-east-2:297980502696:cluster/udacity-cluster
kubectl get pods --all-namespaces
kubectl config set-context --current --namespace=udacity
./initialize_k8s.sh

# hello world
kubectl get pods -n udacity
kubectl -n udacity logs -f deployment/hello-world

# canary
# Check the v1 application and service
kubectl get service canary-svc
# Use an ephemeral container to access the Kubernetes internal network
kubectl run debug --rm -i --tty --image nicolaka/netshoot -- /bin/bash
curl <service_ip>
# Initiate a canary deployment for canary-v2 via a bash script
bash canary.sh
# Edit the canary-svc.yml to allow multiple versions of the application by removing this line version: "1.0"
terraform apply
# Check the v2 application
curl <service_ip>

# blue green
# Connect to the ec2 instance via EC2 Instance Connect
curl blue-green.udacityproject
# Deploy green.yml service to the cluster
kubectl apply -f green.yml
# Delete the blue DNS record
terraform apply
# Connect to the curl-instance and confirm only receiving results from the green service
curl blue-green.udacityproject

# node elasticity
kubectl apply -f bloatware.yml
kubectl get pods -n udacity
kubectl describe pod <node-name>
# Delete the service's deployment 
kubectl delete -f bloatware.yml
# Resolve this problem by increasing the cluster node size
# nodes_desired_size = 4
# nodes_max_size     = 10
# nodes_min_size     = 1
terraform apply
kubectl get pods
# Setup OIDC provider
eksctl utils associate-iam-oidc-provider \
--cluster udacity-cluster \
--approve \
--region=us-east-2
# Create a cluster service account with IAM permissions
eksctl create iamserviceaccount --name cluster-autoscaler --namespace kube-system \
--cluster udacity-cluster --attach-policy-arn "arn:aws:iam::297980502696:policy/udacity-k8s-autoscale" \
--approve --region us-east-2 
# Apply cluster_autoscale.yml configuration to create a service 
# that will listen for events like Node capacity reached to automatically increase the number of nodes in the cluster
kubectl apply -f cluster-autoscaler.yml
kubectl -n kube-system logs -f deployment/cluster-autoscaler
#Launch bloatware.yml to the cluster
kubectl apply -f bloatware.yml

# observability with metrics
kubectl apply -f metrics-server.yml
kubectl top pods

