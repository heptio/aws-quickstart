# Run WordPress with Helm on Kubernetes

![../../_images/banner-twitter.jpg][1]

This tutorial shows how to run WordPress from your Kubernetes cluster. [WordPress][2] is an open-source CMS and blogging platform that powers many of the internet's websites.

We use the [Helm][3] package manager to install the software. Helm is a tool for managing pre-configured Kubernetes objects. It's an easy way to install popular software on Kubernetes.

Note that you'll be using default settings from both [VMware's AWS Quick Start][4] and Helm, so make sure the security options fit your use case.

Take a look at the [WordPress Helm configuration for Kubernetes][5].

## Prerequisites

This tutorial assumes the following:

* You have a local Linux/Unix environment (like a MacBook)
* You have successfully created the CloudFormation stacks from the [AWS Kubernetes Quick Start][6] (or followed [the CLI walkthrough][7] if you prefer)
* You have copied the resulting `kubeconfig` file to your local machine, and can successfully run `kubectl` commands against the cluster (see [Step 4 of the setup guide][8])

Try running `kubectl get nodes`. Your output should look similar to this:
    
    
    NAME               STATUS         AGE
    ip-10-0-0-0     Ready,master      1h
    ip-172-172-172-172 Ready          1h
    ip-192-192-192-192 Ready          1h
    

If it is, your cluster is ready to go! If the output looks substantially different, try running through the [setup walkthrough][7] again.

## 1\. Install or upgrade Helm locally

On your **local machine**, install Helm, a popular package manager for Kubernetes.

On OS X, we recommend using [Homebrew][9] to install Helm.
    
    
    brew install kubernetes-helm
    

If you've already installed Helm, it's a good idea to make sure you're on the latest version:
    
    
    brew upgrade kubernetes-helm
    

Note that the [latest Helm release][10] is often a bit ahead of Homebrew, and may address issues from previous releases.

Check the [Helm website][3] for instructions on installing Helm for other platforms.

## 2\. Initialize Helm and Tiller

On your **local machine**, initialize Helm for your Kubernetes cluster. This will install Tiller (the Helm server-side component) onto the Kubernetes cluster and set up your local configuration. This depends on your `kubeconfig` having the credentials to connect to the Kubernetes cluster, as described in the prerequisites. For more details, see the [Helm documentation][11].

### Install Tiller

Initialize Helm and configure Tiller with this command:

This works with kubectl to connect to your cluster.

Note

If kubectl isn't configured to connect to your cluster, you might see an error like `Error: error installing: Post http://localhost:8080/apis/extensions/v1beta1/namespaces/kube-system/deployments: dial tcp [::1]:8080: getsockopt: connection refused`. Check your prerequisites if you see this error.

You should see output like:
    
    
    $HELM_HOME has been configured at /Users/varMyUser/.helm.
    
    Tiller (the helm server side component) has been installed into your Kubernetes Cluster.
    Happy Helming!
    

If you've already installed Tiller on your cluster, it's a good idea to make sure you're on the latest version:

Optionally, check your Helm and Tiller versions:

If they're not both the latest, run through the previous steps to update Helm and Tiller.

### Implement Tiller RBAC fix

At the time of writing, the version of Tiller installed with Homebrew has not caught up to the new default permission structure in Kubernetes 1.6+. On the 1.6+ Kubernetes cluster built by the AWS Quick Start, RBAC is turned on by default, and the default service account for each namespace does not have admin access. Read more about the RBAC updates and a general approach to Kubernetes permission fixes in our [RBAC workaround guide][12]. Read more about this specific workaround [on the Helm issue][13].

To give Tiller permission to install and configure resources on our cluster, first we create a new [ServiceAccount][14] named `tiller` in the system-wide `kube-system` [Namespace][15].
    
    
    kubectl create serviceaccount --namespace kube-system tiller
    

Create a [ClusterRoleBinding][16] with `cluster-admin` access levels for this new service account named `tiller`. Note that these are very broad permissions, because we want Tiller to be able to install and configure a wide variety of cluster resources.
    
    
    kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
    

Edit the existing Tiller [Deployment][17] named `tiller-deploy`.
    
    
    kubectl edit deploy --namespace kube-system tiller-deploy
    

This will open the YAML configuration for this deployment in a text editor. Insert the line `serviceAccount: tiller` in the `spec: template: spec` section of the file:
    
    
    ...
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: helm
          name: tiller
      strategy:
        rollingUpdate:
          maxSurge: 1
          maxUnavailable: 1
        type: RollingUpdate
      template:
        metadata:
          creationTimestamp: null
          labels:
            app: helm
            name: tiller
        spec:
          serviceAccount: tiller
          containers:
          - env:
            - name: TILLER_NAMESPACE
              value: kube-system
    ...
    

Now Tiller is using the new `tiller` service account we just created, which has expanded permissions. You should be able to successfully use Helm to install your software now.

## 3\. Install WordPress

Create a new Kubernetes [Namespace][15] with:
    
    
    kubectl create namespace varmywordpress
    
    
    
    namespace "varmywordpress" created
    

This sets up a new namespace in your Kubernetes cluster to contain all the objects for the WordPress site.

Use Helm to install WordPress into your new namespace. This configures [everything WordPress needs to run][5], including:
    
    
    helm install --namespace varmywordpress --name wordpress stable/wordpress
    

You will see a large amount of output, starting with:
    
    
    NAME:   wordpress
    LAST DEPLOYED: Mon Feb 27 17:45:42 2017
    NAMESPACE: varmywordpress
    STATUS: DEPLOYED
    ...
    

Read through the rest of the output at your leisure. It contains instructions for accessing your site, but these may not be 100% compatible with AWS because of how the Kubernetes stack's networking is configured. (With AWS, Kubernetes stores a hostname for the load balancer, not the IP.)

We'll show you how to access your WordPress site in the next step.

## 4\. Connect to your WordPress site

You'll need to wait 2-10 minutes for WordPress to finish provisioning.

One issue at time of writing: the command Helm gives for finding the site's IP address may not work. Instead, use the following command to find the URL to the new WordPress site:
    
    
    echo http://$(kubectl get svc --namespace varmywordpress wordpress-wordpress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
    

It should be a lengthy auto-generated URL, like:
    
    
    http://xxxxxx.us-west-2.elb.amazonaws.com
    

It will typically take a few minutes for the new site's DNS to be ready. After this time, you should be able to visit the new site in your browser.

To log in to your WordPress site, use the following credentials:

* Username: **user**
* Password: this is automatically generated

You can fetch the password with this command:
    
    
    echo Password: $(kubectl get secret --namespace varmywordpress wordpress-wordpress -o jsonpath="{.data.wordpress-password}" | base64 --decode)
    

Now you can log into the control panel for WordPress and start crafting your WordPress site running on Kubernetes.

[1]: http://docs.heptio.com/_images/banner-twitter.jpg
[2]: https://wordpress.org/
[3]: http://helm.sh/
[4]: http://docs.heptio.com/aws.html
[5]: https://github.com/kubernetes/charts/tree/master/stable/wordpress
[6]: https://s3.amazonaws.com/quickstart-reference/heptio/latest/doc/heptio-kubernetes-on-the-aws-cloud.pdf
[7]: http://docs.heptio.com/aws-cloudformation-k8s.html
[8]: http://docs.heptio.com/content/tutorials/aws-cloudformation-k8s.html#optional-download-kubectl-configuration
[9]: https://brew.sh
[10]: https://github.com/kubernetes/helm/releases
[11]: https://github.com/kubernetes/helm/blob/master/docs/quickstart.md
[12]: http://docs.heptio.com/rbac.html
[13]: https://github.com/kubernetes/helm/issues/2224
[14]: https://kubernetes.io/docs/admin/service-accounts-admin/
[15]: https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/
[16]: https://kubernetes.io/docs/admin/authorization/rbac/#rolebinding-and-clusterrolebinding
[17]: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/