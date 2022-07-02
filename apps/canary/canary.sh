DEPLOY_INCREMENTS=1

function manual_verification {
  read -p "Continue deployment? (y/n) " answer

    if [[ $answer =~ ^[Yy]$ ]] ;
    then
        echo "continuing deployment"
    else
        exit
    fi
}

function canary_deploy {
  NUM_OF_V1_PODS=$(kubectl get pods -n udacity | grep -c canary-v1)
  echo "V1 PODS: $NUM_OF_V1_PODS"
  NUM_OF_V2_PODS=$(kubectl get pods -n udacity | grep -c canary-v2)
  echo "V2 PODS: $NUM_OF_V2_PODS"

  kubectl scale deployment canary-v2 --replicas=$((NUM_OF_V2_PODS + $DEPLOY_INCREMENTS)) -n udacity
  kubectl scale deployment canary-v1 --replicas=$((NUM_OF_V1_PODS - $DEPLOY_INCREMENTS)) -n udacity
  # Check deployment rollout status every 1 second until complete.
  ATTEMPTS=0
  ROLLOUT_STATUS_CMD="kubectl rollout status deployment/canary-v2 -n udacity"
  until $ROLLOUT_STATUS_CMD || [ $ATTEMPTS -eq 60 ]; do
    $ROLLOUT_STATUS_CMD
    ATTEMPTS=$((attempts + 1))
    sleep 1
  done
  echo "Canary deployment of $DEPLOY_INCREMENTS replicas successful!"
}

# Initialize canary-v2 deployment
kubectl apply -f canary-v2.yml

sleep 1
# Begin canary deployment
while [ $(kubectl get pods -n udacity | grep -c canary-v1) -gt 0 ]
do
  canary_deploy
  manual_verification
done

echo "Canary deployment of v2 successful"


# kubectl get service canary-svc
# kubectl run debug --rm -i --tty --image nicolaka/netshoot -- /bin/bash
# curl <service_ip>
# kubectl get pods -n udacity | grep -c canary-v1
# kubectl scale deployment canary-v2 --replicas=4 -n udacity