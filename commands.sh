aws s3api create-bucket --bucket udacity-tf --region us-east-2 --create-bucket-configuration LocationConstraint=us-east-2
# aws s3 rm s3://udacity-tf --recursive
terraform init
terraform apply
aws eks --region us-east-2 update-kubeconfig --name udacity-cluster
kubectl config use-context arn:aws:eks:us-east-2:297980502696:cluster/udacity-cluster
kubectl get pods --all-namespaces
kubectl config set-context --current --namespace=udacity
./initialize_k8s.sh

kubectl get pods -n udacity
kubectl -n udacity logs -f deployment/hello-world

eksctl utils associate-iam-oidc-provider \
--cluster udacity-cluster \
--approve \
--region=us-east-2

kubectl -n kube-system logs -f deployment/cluster-autoscaler

eksctl create iamserviceaccount --name cluster-autoscaler --namespace kube-system \
--cluster udacity-cluster --attach-policy-arn "arn:aws:iam::297980502696:policy/udacity-k8s-autoscale" \
--approve --region us-east-2 

kubectl apply -f metrics-server.yml
kubectl top pods