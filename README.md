[![build](https://github.com/symas/helm-openldap/actions/workflows/ci.yml/badge.svg?branch=master)](https://github.com/symas/helm-openldap/actions/workflows/ci.yml)
[![Artifact HUB](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/symas-openldap)](https://artifacthub.io/packages/search?repo=symas-openldap)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://github.com/apache/apisix/blob/master/LICENSE)
![Version](https://img.shields.io/static/v1?label=Openldap&message=2.6.3&color=blue)

# Supported OpenLDAP Helm Chart by Symas Corp

## TL;DR

To install the chart with the release name `my-release`:

```bash
$ helm repo add helm-openldap https://symas.github.io/helm-openldap/
$ helm install my-release helm-openldap/openldap-stack-ha
```

## What's here?

A Helm cart to deploy and manage your [OpenLDAP](https://openldap.org) instance on
Kubernetes provided by [Symas](https://symas.com), ready for production use.


## How to contact Symas for commercial support

This [Helm chart](https://helm.sh/) packages the [Symas OpenLDAP container](https://github.com/symas/containers/tree/main/openldap).  For general help on OpenLDAP please take a look at our [knowledge base](https://kb.symas.com/), or go to the [OpenLDAP site](https://openldap.org/) and read the [documentation](https://openldap.org/doc/), the [quick start guide](https://openldap.org/doc/admin26/quickstart.html), and the detailed [manual pages](https://openldap.org/software/man.cgi).  [What we publish](https://repo.symas.com) is what we provide to you in this format to help you adopt and use OpenLDAP.  As always, everything is open-source.

If you need help, please contact us at: +1.650.963.7601 or email [sales](mailto:sales@symas.com) or send mail to our [support](mailto:support@symas.com) teams directly with questions.  More on our support offerings can be [found on our website](https://www.symas.com/symas-tech-support).  We're also available on the Symas Discord [#openldap](https://discord.gg/t6upYQDx2) channel and chat with us directly.

Reach out to us, we're here to help.


## Why use our OpenLDAP chart?

* Symas has, for over a decade, built, maintained, and commercially supported
  the OpenLDAP codebase.
* All our work on OpenLDAP has always been, and will always be open-source.  We
  are a [commercial support company](mailto:support@symas.com), here if and when
  you need us.
* We commit to promptly publish new versions of this chart for every release of
  the software going forward.
* Our images contain the latest bug fixes and features released, not just in OpenLDAP
  but in supporting libraries.
* We've based our chart on the existing [jp-gouin](https://github.com/jp-gouin/helm-openldap)
  chart that uses the [Bitnami containers](https://github.com/bitnami/containers/)
  having recently changed from the abandoned Osixia OpenLDAP containers.
* We'd like to thank [Jean-Philippe Gouin](https://github.com/jp-gouin) for open sourcing his work allowing the community to benefit.  Our shared philosophy makes us stronger.


## Why not just contribute to Jean-Philippe's exiting chart?

We may eventually merge our work into his, for now we'd like to remain on a fork
that we provide and support for our customers that is under our direct control.

Fundamentally, we're a company that supports OpenLDAP as our primary business
model so it is important for us to own this Helm chart allowing for easy deployent
of OpenLDAP within Kubernetes clusters.

- Replication is setup by configuration. Extra schemas are loaded using `LDAP_EXTRA_SCHEMAS: "cosine,inetorgperson,nis,syncprov,serverid,csyncprov,rep,bsyncprov,brep,acls`. You can add your own schemas to load during setup via the `customSchemaFiles` option.

A default tree (Root Organization, users and group) is created during startup, this can be skipped using `LDAP_SKIP_DEFAULT_TREE`, however you need to use `customLdifFiles` or `customLdifCm` to create a root organization.


## Prerequisites

* Kubernetes 1.8+
* Persistent Volume (PV) support on the underlying infrastructure

## Chart Details:

This chart will:

* Create 3 instances of OpenLDAP server with multi-master replication.
* Install and configure a single pod running [phpldapadmin](https://github.com/leenooks/phpLDAPadmin) using the [Osixia container](https://github.com/osixia/docker-phpLDAPadmin), an admin web-GUI for OpenLDAP.
* Install and configure [ltb-passwd](https://ltb-project.org/documentation/self-service-password.html) using the [Tired of It container](https://github.com/tiredofit/docker-self-service-password) for self-service password changes.

## Symas Packaged OpenLDAP

We, at Symas, contribute to and maintain the [OpenLDAP software](https://openldap.org) as open source software.  We work within the community of contributors to this project, that's how open source works.  We don't sell licenses to the software, the software is free for anyone to use.  We do provide commercial support for OpenLDAP, and in that capacity we've run across bugs that others may not have encountered.  We fix those issues and contribute them back to OpenLDAP through the community process.  Sometimes we find bugs impacting OpenLDAP in supporting libraries, and in those cases we fix those issues and offer them to the package maintainers.  When that process isn't fast enough, we apply our fixes to a fork of the package and include that within our package of OpenLDAP.  When that fix is upstreamed and released, we return to using the community provided library.  All that is to say that it is possible that the Symas supplied packages include fixes that are not available in other builds of OpenLDAP unless those builds included our forks of those dependencies.

In addition, Symas sometimes includes packages or configuration by default that we've found useful to our customers.  For instances, this Helm chart includes lib-passwd which is a web-based self-service password management application developed by the Linux toolbox Project. It has some nice features useful when administering OpenLDAP. Ppm is a password complexity module for OpenLDAP, it also comes password management features, but the only overlap between Ppm and lib-passwd is that they both can enforce password complexity rules, albeit in different ways.  So, with this release of OpenLDAP you get the best of both worlds.


## Configuration

We use the [Symas provided container image](https://github.com/symas/containers/tree/main/openldap) forked from, and compatible with, the [Bitnami OpenLDAP container](https://github.com/bitnami/containers/tree/main/bitnami/openldap). Please consult to documentation of the image for more information.

The following table lists the configurable parameters of the openldap chart and their default values.

### Global section

Global parameters to configure the deployment of the application.

| Parameter                          | Description                                                                                                                               | Default             |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- | ------------------- |
| `global.imageRegistry`                     | Global image registry                                                                                                                        | `""`                 |
| `global.imagePullSecrets`                     | Global list of imagePullSecrets                                                                                                                        | `[]`                 |
| `global.ldapDomain`                     | Domain LDAP can be explicit `dc=example,dc=org` or domain based `example.org`                                                                                                                         | `example.org`                 |
| `global.existingSecret`                     | Use existing secret for credentials - the expected keys are LDAP_ADMIN_PASSWORD and LDAP_CONFIG_ADMIN_PASSWORD                                         | `""`                |
| `global.adminUser`                     | Openldap database admin user                                                                                                                        | `admin`                 |
| `global.adminPassword`                     | Administration password of Openldap                                                                                                                        | `Not@SecurePassw0rd`                 |
| `global.configUserEnabled`                     |  Whether to create a configuration admin user                                                                                                                       | `true`                 |
| `global.configUser`                     |  Openldap configuration admin user                                                                                                                       | `admin`                 |
| `global.configPassword`                     | Configuration password of Openldap                                                                                                                        | `Not@SecurePassw0rd`                 |
| `global.ldapPort`                     | Ldap port                                                                                                                         | `389`                 |
| `global.sslLdapPort`                     | Ldaps port                                                                                                                         | `636`                 |

### Application parameters

Parameters related to the configuration of the application.

| Parameter                          | Description                                                                                                                               | Default             |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- | ------------------- |
| `replicaCount`                     | Number of replicas                                                                                                                        | `3`                 |
| `users`          | User list to create (comma separated list) , can't be use with customLdifFiles | "" |
| `userPasswords`          | User password to create (comma seprated list)  | "" |
| `group`          | Group to create and add list of user above | "" |
| `env`                              | List of key value pairs as env variables to be sent to the docker image. See https://github.com/symas/containers/tree/main/openldap for available ones | `[see values.yaml]` |
| `customTLS.enabled`                      | Set to enable TLS/LDAPS with custom certificate - should also set `tls.secret`                                                                                    | `false`             |
| `customTLS.secret`                       | Secret containing TLS cert and key must contain the keys tls.key , tls.crt and ca.crt                                                                       | `""`                |
| `customSchemaFiles` | Custom openldap schema files used in addition to default schemas                                                                    | `""`                |
| `customLdifFiles`                       | Custom openldap configuration files used to override default settings                                                                      | `""`                |
| `customLdifCm`                       | Existing configmap with custom ldif. Can't be use with customLdifFiles                                                            | `""`                |
| `customAcls`                       | Custom openldap ACLs. Overrides default ones.                                                                      | `""`                |
| `replication.enabled`              | Enable the multi-master replication | `true` |
| `replication.retry`              | retry period for replication in sec | `60` |
| `replication.timeout`              | timeout for replication  in sec| `1` |
| `replication.starttls`              | starttls replication | `critical` |
| `replication.tls_reqcert`              | tls certificate validation for replication | `never` |
| `replication.interval`             | interval for replication | `00:00:00:10` |
| `replication.clusterName`          | Set the clustername for replication | "cluster.local" |

### Phpladadmin configuration

Parameters related to PHPLdapAdmin

| Parameter                          | Description                                                                                                                               | Default             |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- | ------------------- |
| `phpldapadmin.enabled`             | Enable the deployment of PhpLdapAdmin | `true`|
| `phpldapadmin.ingress`             | Ingress of Phpldapadmin | `{}` |
| `phpldapadmin.env`  | Environment variables for PhpldapAdmin| `{PHPLDAPADMIN_LDAP_CLIENT_TLS_REQCERT: "never"}` |

For more advance configuration see [README.md](./advanced_examples/README.md)  
For all possible chart parameters see chart's [README.md](./charts/phpldapadmin/README.md)

### Self-service password configuration

Parameters related to Self-service password.

| Parameter                          | Description                                                                                                                               | Default             |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- | ------------------- |
|`ltb-passwd.enabled`| Enable the deployment of Ltb-Passwd| `true` |
|`ltb-passwd.ingress`| Ingress of the Ltb-Passwd service | `{}` |

For more advance configuration see [README.md](./advanced_examples/README.md)  
For all possible parameters see chart's [README.md](./charts/ltb-passwd/README.md)

### Kubernetes parameters

Parameters related to Kubernetes.

| Parameter                          | Description                                                                                                                               | Default             |
| ---------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------- | ------------------- |
| `updateStrategy`                   | StatefulSet update strategy                                                                                                               | `{}`                |
| `kubeVersion`                 | kubeVersion Override Kubernetes version                                                                                                                | `""`   |
| `nameOverride`                        | String to partially override common.names.fullname                                                                                                                       | `""`            |
| `fullnameOverride`                 | fullnameOverride String to fully override common.names.fullname                                                                                                                     | `""`      |
| `commonLabels`                      | commonLabels Labels to add to all deployed objects                                                                                                            | `{}`                |
| `clusterDomain`                   | clusterDomain Kubernetes cluster domain name                                                                                                             | `cluster.local`                |
| `extraDeploy`                   | extraDeploy Array of extra objects to deploy with the release                                                                                | `""`                |
| `service.annotations`              | Annotations to add to the service                                                                                                         | `{}`                |
| `service.externalIPs`              | Service external IP addresses                                                                                                             | `[]`                |
| `service.ldapPortNodePort`                 | Nodeport of External service port for LDAP if service.type is NodePort                                                                                                            | `nil`               |
| `service.loadBalancerIP`           | IP address to assign to load balancer (if supported)                                                                                      | `""`                |
| `service.loadBalancerSourceRanges` | List of IP CIDRs allowed access to load balancer (if supported)                                                                           | `[]`                |
| `service.sslLdapPortNodePort`                 | Nodeport of External service port for SSL if service.type is NodePort                                                                                                            | `nil`               |
| `service.type`                     | Service type can be ClusterIP, NodePort, LoadBalancer                                                                                                                              | `ClusterIP`         |
| `persistence.enabled`              | Whether to use PersistentVolumes or not                                                                                                   | `false`             |
| `persistence.storageClass`         | Storage class for PersistentVolumes.                                                                                                      | `<unset>`           |
| `persistence.existingClaim`        | Add existing Volumes Claim. | `<unset>`           |
| `persistence.accessMode`           | Access mode for PersistentVolumes                                                                                                         | `ReadWriteOnce`     |
| `persistence.size`                 | PersistentVolumeClaim storage size                                                                                                        | `8Gi`               |
| `extraVolumes`                     | Allow add extra volumes which could be mounted to statefulset | None |
| `extraVolumeMounts`                | Add extra volumes to statefulset | None |
| `customReadinessProbe`                    | Liveness probe configuration                                                                                                              | `[see values.yaml]` |
| `customLivenessProbe`                   | Readiness probe configuration                                                                                                             | `[see values.yaml]` |
| `customStartupProbe`                     | Startup probe configuration                                                                                                               | `[see values.yaml]` |
| `resources`                        | Container resource requests and limits in yaml                                                                                            | `{}`                |
| `podSecurityContext`              | Enabled OPENLDAP  pods' Security Context | `true` |``
| `containerSecurityContext`              | Set OPENLDAP  pod's Security Context fsGroup | `true` |
| `existingConfigmap`              | existingConfigmap The name of an existing ConfigMap with your custom configuration for OPENLDAP  | `` |
| `podLabels`              | podLabels Extra labels for OPENLDAP  pods| `{}` |
| `podAnnotations`              | podAnnotations Extra annotations for OPENLDAP  pods | `{}` |
| `podAffinityPreset`              | podAffinityPreset Pod affinity preset. Ignored if `affinity` is set. Allowed values: `soft` or `hard`| `` |
| `podAntiAffinityPreset`              | podAntiAffinityPreset Pod anti-affinity preset. Ignored if `affinity` is set. Allowed values: `soft` or `hard` | `soft` |
| `pdb.enabled`                      | Enable Pod Disruption Budget                                                                                                              | `false`             |
| `pdb.minAvailable`                 | Configure PDB to have at least this many health replicas.                                                                                 | `1`                 |
| `pdb.maxUnavailable`               | Configure PDB to have at most this many unhealth replicas.                                                                                | `<unset>`           |
| `nodeAffinityPreset`              | nodeAffinityPreset.type Node affinity preset type. Ignored if `affinity` is set. Allowed values: `soft` or `hard` | `true` |
| `affinity`              | affinity Affinity for OPENLDAP  pods assignment | `` |
| `nodeSelector`              | nodeSelector Node labels for OPENLDAP  pods assignment | `` |
| `sidecars`              | sidecars Add additional sidecar containers to the OPENLDAP  pod(s) | `` |
| `initContainers`              | initContainers Add additional init containers to the OPENLDAP  pod(s) | `` |
| `volumePermissions`              | 'volumePermissions' init container parameters | `` |
| `priorityClassName`              | OPENLDAP pods' priority class name | `` |
| `tolerations`              | Tolerations for pod assignment | [] |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`.

Alternatively, a YAML file that specifies the values for the parameters can be provided while installing the chart. For example,

```bash
$ helm install --name my-release -f values.yaml stable/openldap
```

> **Tip**: You can use the default [values.yaml](values.yaml)


## PhpLdapAdmin

To enable [PhpLdapAdmin](https://github.com/leenooks/phpLDAPadmin) set `phpldapadmin.enabled`  to `true`

Ingress can be configure if you want to expose the service.
Setup the env part of the configuration to access the OpenLdap server

**Note** : The ldap host should match the following `namespace.Appfullname`

Example :
```
phpldapadmin:
  enabled: true
  ingress:
    enabled: true
    annotations: {}
    # Assuming that ingress-nginx is used
    ingressClassName: nginx
    path: /
    ## Ingress Host
    hosts:
    - phpldapadmin.local
  env:
    PHPLDAPADMIN_LDAP_CLIENT_TLS_REQCERT: "never"

```
## Self-service-password
To enable Self-service-password set `ltb-passwd.enabled`  to `true`

Ingress can be configure if you want to expose the service.

Setup the `ldap` part with the information of the OpenLdap server.

Set `bindDN` accordingly to your ldap domain

**Note** : The ldap server host should match the following `ldap://namespace.Appfullname`

Example :
```
ltb-passwd:
  enabled : true
  ingress:
    enabled: true
    annotations: {}
    # Assuming that ingress-nginx is used
    ingressClassName: nginx
    host: "ssl-ldap2.local"

```

## Cleanup orphaned Persistent Volumes

Deleting the Deployment will not delete associated Persistent Volumes if persistence is enabled.

Do the following after deleting the chart release to clean up orphaned Persistent Volumes.

```bash
$ kubectl delete pvc -l release=${RELEASE-NAME}
```

## Custom Secret

`global.existingSecret` can be used to override the default secret.yaml provided


## Troubleshoot

You can increase the level of log using `env.LDAP_LOGLEVEL`

Valid log levels can be found [here](https://www.openldap.org/doc/admin24/slapdconfig.html)

### Boostrap custom ldif

**Warning** when using custom ldif in the `customLdifFiles` or `customLdifCm` section you  have to create the high level object `organization`

```
dn: dc=test,dc=example
dc: test
o: Example Inc.
objectclass: top
objectclass: dcObject
objectclass: organization
```

**note** the admin user is created by the application and should not be added as a custom ldif

All internal configuration like `cn=config` , `cn=module{0},cn=config` cannot be configured yet.

## Changelog/Updating

### To 1.0.0

The Symas fork of the [jp-gouin](https://github.com/jp-gouin/helm-openldap) Helm chart so as to use our containers and provide commercial support.

