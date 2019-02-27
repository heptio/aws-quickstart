# RBAC best practices and workarounds

## Introduction

Role-based access control, or RBAC, means that different accounts that authenticate to a Kubernetes cluster have different permission levels.

The Kubernetes documentation covers [Using RBAC Authorization][1].

RBAC means you will run into permission errors on your cluster if you don't set appropriate access settings. In production environments, you **do not** want to turn off RBAC entirely or give everything root, as this is a major security risk.

Here we provide a few recommendations and workarounds to get permissions working on your cluster, since the `default` service account has no permissions that you don't grant it, following the 1.6 minor point release. (Before the RBAC feature, the `default` service account had the equivalent of `root` on the cluster in many deployments.)

## Grant access for specific service accounts (more secure)

The most secure option for RBAC is to have your application create a service account for itself with only the permissions it needs.

The next least permissive option is to create a specific service account for an application that has admin access to that application's namespace.

These options require you to write RBAC policies. Full documentation can be found in the Kubernetes article, [Using RBAC Authorization][1].

## Grant access for the default service account (less secure)

The third option, which is a good quick permissions workaround if less secure, is to grant admin access to the default service account for a particular namespace to that same application namespace. You can do this on a namespace by namespace basis.

Do this by creating a new [RoleBinding][2]. Replace the namespace `varMyNamespace` to give the default service account admin access to the [namespace][3] for a particular application:
    
    
    kubectl create rolebinding varMyRoleBinding 
      --clusterrole=admin 
      --serviceaccount=varMyNamespace:default 
      --namespace=varMyNamespace
    

The last option to get around the new RBAC permissions without completely turning them off is to give the `kube-system` default service account admin access to the whole cluster. Most things that operate across the entire cluster run in kube-system. This is a very broad-brushed approach, **and not secure**, but it should get you past permission errors due to RBAC.

Do this by creating a new [ClusterRoleBinding][2]. This lets the default service account operate outside its namespace:
    
    
    kubectl create clusterrolebinding varMyClusterRoleBinding 
      --clusterrole=cluster-admin 
      --serviceaccount=kube-system:default
    

[1]: https://kubernetes.io/docs/admin/authorization/rbac/
[2]: https://kubernetes.io/docs/admin/authorization/rbac/#rolebinding-and-clusterrolebinding
[3]: https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/