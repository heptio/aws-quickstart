# Expose Services on your AWS Quick Start Kubernetes cluster

![../../_images/banner-twitter.jpg][1]

This tutorial explains how to run a basic service on your Kubernetes cluster and expose it to the Internet using Amazon's [Elastic Load Balancing (ELB)][2].

## Prerequisites

This tutorial assumes the following:

* You have a local Linux/Unix environment (like a MacBook)
* You have successfully created the CloudFormation stacks from the [AWS Kubernetes Quick Start][3] (or followed [the CLI walkthrough][4] if you prefer)
* You have copied the resulting `kubeconfig` file to your local machine, and can successfully run `kubectl` commands against the cluster (see [Step 4 of the setup guide][5])

Try running `kubectl get nodes`. Your output should look similar to this:
    
    
    NAME               STATUS         AGE
    ip-10-0-0-0     Ready,master      1h
    ip-172-172-172-172 Ready          1h
    ip-192-192-192-192 Ready          1h
    

If it is, your cluster is ready to go! If the output looks substantially different, try running through the [setup walkthrough][4] again.

## 1\. Deploy a simple demo application

For the example we'll run the [echoheaders][6] app, which is a simple nginx server that prints the headers it receives.

First we create a new namespace under which the application will run:
    
    
    kubectl create namespace simple-demo
    

Example output:
    
    
    $ kubectl create namespace simple-demo
    namespace "simple-demo" created
    

Next we run our application within the namespace, using a single command:
    
    
    kubectl run --namespace simple-demo echoheaders --image=gcr.io/google_containers/echoserver:1.4 --replicas=1 --port=8080
    

This creates a deployment named `echoheaders` on your cluster, which will run a single replica of the `echoserver` container, listening on port 8080. The deployment will re-launch the container automatically if it ever crashes.

Let's look at what was created in the `simple-demo` namespace after we ran the deployment:
    
    
    $ kubectl run --namespace simple-demo echoheaders --image=gcr.io/google_containers/echoserver:1.4 --replicas=1 --port=8080
    deployment "echoheaders" created
    $ kubectl get all --namespace simple-demo
    NAME                              READY     STATUS    RESTARTS   AGE
    po/echoheaders-2787888573-c3nt1   1/1       Running   0          11m
    
    NAME                 DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
    deploy/echoheaders   1         1         1            1           11m
    
    NAME                        DESIRED   CURRENT   READY     AGE
    rs/echoheaders-2787888573   1         1         1         11m
    

We see:

* A single Pod, `po/echoheaders-2787888573-c3nt1`, which runs the echoserver container
* A single Replica Set, `rs/echoheaders-2787888573`, which manages the Pod and restarts it if it ever fails
* A single Deployment, `deploy/echoheaders`, which is the object that created the Replica Set. This can be edited to update the application without causing downtime.

## 2\. Expose our application to the Internet

Next we can use `kubectl expose` to create a Service that exposes our new application to the Internet over an AWS Elastic Load Balancer (ELB).

Let's run the following command:
    
    
    kubectl expose --namespace=simple-demo deployment echoheaders --type=LoadBalancer --port=80 --target-port=8080 --name=echoheaders-public
    

This will create a Service object, which acts as an endpoint for routing to an instance of the `echoheaders` application.

After we expose the deployments, we can inspect the results with `kubectl describe`:
    
    
    $ kubectl --namespace=simple-demo describe service echoheaders-public
    Name:           echoheaders-public
    Namespace:      simple-demo
    Labels:         run=echoheaders
    Selector:       run=echoheaders
    Type:           LoadBalancer
    IP:         10.103.66.255
    LoadBalancer Ingress:   a9201a1bdfc6411e68fdc06048bde387-495139964.us-west-1.elb.amazonaws.com
    Port:            80/TCP
    NodePort:        30031/TCP
    Endpoints:      192.168.96.196:8080
    Session Affinity:   None
    Events:
      FirstSeen LastSeen    Count   From            SubObjectPath   Type        Reason          Message
      --------- --------    -----   ----            -------------   --------    ------          -------
      2m        2m      1   {service-controller }           Normal      CreatingLoadBalancer    Creating load balancer
      1m        1m      1   {service-controller }           Normal      CreatedLoadBalancer Created load balancer
    

This describes the `echoheaders-public` service that was just created. Because it is `type=LoadBalancer`, we have a public-facing URL under the `LoadBalancer Ingress` section. We can now browse to the resulting URL and see our application:

![../../_images/echoheaders-screenshot.png][7]

The port for the service is 80, which is the public external port for this service. But the endpoint is on port 8080, which is the port the container itself is listening on.

For more information about Services, see the [Kubernetes User Guide reference for Services][8].

## Reference: The kubectl expose command
    
    
    NAMESPACE=simple-demo
    RESOURCETYPE=deployment
    RESOURCENAME=echoheaders
    SERVICETYPE=LoadBalancer
    PORT=80
    TARGETPORT=8080
    SERVICENAME=echoheaders-public
    
    kubectl expose --namespace=$NAMESPACE 
    $RESOURCETYPE $RESOURCENAME 
    --type=$SERVICETYPE 
    --port=$PORT --target-port=$TARGETPORT 
    --name=$SERVICENAME
    

Parameter | Description
--- | ---
NAMESPACE | Not required. The namespace under which the application was created. Defaults to `default`.
RESOURCETYPE | Required. The type of underlying Kubernetes resource to expose as a Service. Possible resources include: Pod, Service, ReplicationController, Deployment, ReplicaSet.
RESOURCENAME | Required. The name of the resource to expose. In this case, it's the name of the Deployment we created.
SERVICETYPE | Not required. The type of service to expose. Defaults to `ClusterIP`. For a detailed description of Service types, see [Kubernetes Service Types][9].
PORT | Not required. The port to expose the Service endpoint on. Defaults to the exposed ports of the underlying Kubernetes resource, but a different port can be specified.
TARGETPORT | Not required. The port that the underlying resource exposes that should be mapped to the Service. Defaults to the exposed port of the resource.
SERVICENAME | Required. The name to give the Service resource in Kubernetes.

For a full reference on the `kubectl expose` command, see the [Kubernetes Community documentation][10].

[1]: http://docs.heptio.com/_images/banner-twitter.jpg
[2]: https://aws.amazon.com/elasticloadbalancing/
[3]: https://s3.amazonaws.com/quickstart-reference/heptio/latest/doc/heptio-kubernetes-on-the-aws-cloud.pdf
[4]: http://docs.heptio.com/aws-cloudformation-k8s.html
[5]: http://docs.heptio.com/content/tutorials/aws-cloudformation-k8s.html#optional-download-kubectl-configuration
[6]: https://github.com/kubernetes/contrib/tree/master/ingress/echoheaders
[7]: http://docs.heptio.com/_images/echoheaders-screenshot.png
[8]: https://kubernetes.io/docs/user-guide/services/
[9]: https://kubernetes.io/docs/user-guide/services/#publishing-services---service-types
[10]: https://kubernetes.io/docs/user-guide/kubectl/kubectl_expose/