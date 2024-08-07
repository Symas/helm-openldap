# Examples of advanced configurations

You will find here some examples of advanced configurations.


## Use your own logos
To use your own logos for password portal, first create a configmap with your
logos.  For instance, a configmap with 2 keys:
- my-logo.png: logo with size for instance 450x128 pixels
- my-logo_50.png: smaller logo, for instance 180x50 pixels

Next, configure such that your logos appear in the containers:
```yaml
ltb-passwd:
   initContainers:
	 - name: install-logo
	   image: "{{ tpl .Values.image.repository . }}:{{ tpl .Values.image.tag . }}"
	   command: [sh, -c]
	   args:
		 - |-
		   cat <<EOF >/data/31-logo
		   #!/command/with-contenv bash
		   source /assets/functions/00-container
		   PROCESS_NAME="logo"
		   cp /tmp/ltb-logo.png /www/ssp/images/ltb-logo.png
		   chmod +x /data/31-logo
		   liftoff
		   EOF
	   volumeMounts:
		 - name: data
		   mountPath: /data
  volumes:
	- name: logos
	  configMap:
		name: logos
	- name: data
	  emptyDir: {}
  volumeMounts:
	- name: logos
	  mountPath: /tmp/ltb-logo.png
	  subPath: my-logo.png
	- name: data
	  mountPath: /etc/cont-init.d/31-logo
	  subPath: 31-logo
```

## Use a user with restricted permissions for password portal
Avoid the default ```cn=admin``` account for the password portal when retrieving
the users.  Instead, define here a user with restricted permissions (only
read-only on attributes except passwords).  Set a password as a separated
secret, thereby allowing vault solutions. For that, we need to define a custom
ldif and custom acls.

First, create a custom ldif file (or add it directly in the values file):
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-customldif
data:
  00-root.ldif: |-
	dn: dc=mydomain,dc=com
	objectClass: top
	objectClass: dcObject
	objectClass: organization
	o: MY-DOMAIN
	dc: mydomain
  01-admin-read-user.ldif: |-
	dn: cn=admin-read,dc=mydomain,dc=com
	cn: admin-read
	mail: admin-read@mydomain.com
	objectClass: inetOrgPerson
	objectClass: top
	userPassword:: {SSHA}xxxxxxxxxxxx
	sn: Admin read only
  02-users-group.ldif: |-
	dn: ou=users,dc=mydomain,dc=com
	ou: users
	objectClass: organizationalUnit
	objectClass: top
  03-foo-user.ldif: |-
	dn: cn=foo,ou=users,dc=mydomain,dc=com
	cn: foo
	objectClass: inetOrgPerson
	objectClass: top
	sn: Foo Foo
	mail: foo@mydomain.com
	userPassword:: {SSHA}xxxxxxxxx
```

Now create a secret for the passwords:
```yaml
kind: Secret
apiVersion: v1
metadata:
  name: openldap-secrets
type: Opaque
stringData:
  LDAP_ADMIN_PASSWORD: xxxxxxxx
  LDAP_CONFIG_ADMIN_PASSWORD: xxxxxxxx
  LDAP_ADMIN_READ_PASSWORD: xxxxxxxx
```

Next configure the values to use this secret, set the correct acls for ```admin-read``` and configure password portal to use this account:
```yaml
global:
  existingSecret: "openldap-secrets"

customAcls: |-
  dn: olcDatabase={2}mdb,cn=config
  changetype: modify
  replace: olcAccess
  olcAccess: {0}to *
	by dn.exact=gidNumber=0+uidNumber=1001,cn=peercred,cn=external,cn=auth manage
	by * break
  olcAccess: {1}to attrs=userPassword,shadowLastChange
	by self write
	by dn="cn=admin,dc=mydomain,dc=com" write
	by anonymous auth by * none
  olcAccess: {2}to *
	by dn="cn=admin-read,dc=mydomain,dc=com" read
	by dn="cn=admin,dc=mydomain,dc=com" write
	by self read
	by * none

ltb-passwd:
  ldap:
	searchBase: "ou=users,dc=mydomain,dc=com"
	bindDN: "cn=admin-read,dc=mydomain,dc=com"
	passKey: LDAP_ADMIN_READ_PASSWORD
```
