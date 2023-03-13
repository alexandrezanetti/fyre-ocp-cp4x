

#!/bin/bash
echo "###### START - ZZZ SCRIPT - PREPARING OPENSHIFT (OCP) ON FYRE TO INSTALL CLOUD PAK FOR X (CP4X)"
export START=$(date)

yum install openldap-clients -y
pause

clear
echo "##############################################"
echo "##############################################"
echo "##############################################"
echo "##############################################"
echo "Por favor informe seu email:"
echo "##############################################"
echo "##############################################"
echo "##############################################"
read email
echo $email

manager=$(ldapsearch -x -H ldaps://bluepages.ibm.com:636 -b "c=br,ou=bluepages,o=ibm.com" -s sub "(emailAddress=$email)" | grep "managerSerialNumber: " | cut -c22-27)
echo $manager

#ldapsearch -x -H ldaps://bluepages.ibm.com:636 -b "c=br,ou=bluepages,o=ibm.com" -s sub "(managerSerialNumber=$manager)" | grep "emailAddress:"  | grep -v "BR0\|BR-" | grep "@" | sed "s/emailAddress: //g" > emails.txt
#cat emails.txt
ldapsearch -x -LLL -H ldaps://bluepages.ibm.com:636 -b "c=br,ou=bluepages,o=ibm.com" -s sub "(managerSerialNumber=$manager)" dn hrFirstName hrLastName preferredIdentity >listapessoas.txt
cat listapessoas.txt
#oc get identity
#oc create user apaes
#echo -n ""uid=101391631,c=br,ou=bluepages,o=ibm.com"" | base64
#oc create identity ldapauth:<identity>
#oc create useridentitymapping ldapauth:<identity> apaes
#oc adm policy add-role-to-user admin alexandre.zanetti@br.ibm.com -n cp4i

echo "Check your IBM Entitlement Key - https://myibm.ibm.com/products-services/containerlibrary" 
echo $IBMENTITLEMENTKEY
if [ ${IBMENTITLEMENTKEY} = "{###PROVIDE_YOUR_IBM_ENTITLEMENT_KEY_HERE###}" ]; then echo "Please provide your IBM Entitlement Key - Check https://myibm.ibm.com/products-services/containerlibrary"; exit 999; fi

echo "Check your Project (Namespace) name" 
if [ ${PROJECT} = "{###PROVIDE_YOUR_PROJECT_NAMESPACE_CP4X_HERE###}" ]; then echo "Please provide your Project/Namespace (CP4x)"; exit 999; fi
PROJECT=$(echo $PROJECT | tr A-Z a-z)
echo $PROJECT
oc new-project $PROJECT
oc project $PROJECT

echo "Creating the installation directory - in general /tmp/cp4x" 
export DIR_CP4X_INST=/tmp/CP4X
echo $DIR_CP4X_RWX

echo "Discovering IPs" 
ip a | grep " 10." | grep inet > ipa10.txt
export IPA10IPWCIDR=$(awk '/ inet / {print $2}' ipa10.txt)
export IPA10IP=$(awk '/ inet / {print $2}' ipa10.txt | egrep -o '^[^/]+')
ip a | grep " 9." | grep inet > ipa9.txt
export IPA9IPCIDR=$(awk '/ inet / {print $2}' ipa9.txt)
export IPA9IP=$(awk '/ inet / {print $2}' ipa9.txt | egrep -o '^[^/]+')
echo $IPA10IPWCIDR
echo $IPA10IP
echo $IPA9IPCIDR
echo $IPA9IP

echo "Generating BASE64 with user CP + IBM Entitlement Key" 
echo -n "cp:$IBMENTITLEMENTKEY" | base64 > CPIBMENTITLEMENTKEYBASE64.txt
export CPIBMENTITLEMENTKEYBASE64=$(cat CPIBMENTITLEMENTKEYBASE64.txt | sed ':a;N;$!ba;s/\n//g')
echo $CPIBMENTITLEMENTKEYBASE64

echo "Generating entitlement key for CR deployment" 
export PARMDEP=$(echo "},\"cp.icr.io\":{\"auth\": \"$CPIBMENTITLEMENTKEYBASE64\"}}}")
echo $PARMDEP

echo "Discover OCP routes (API and Console)" 
oc get routes --all-namespaces | grep -i console-openshift > url-console.txt
export OCPURLCON=https://$(awk '/ console-/ {print $3}' url-console.txt)
export OCPURLAPI=$( oc config view --minify -o jsonpath='{.clusters[*].cluster.server}')
export OCPADMINUSER=kubeadmin
export OCPADMINPASS=$(cat $HOME/auth/$OCPADMINUSER-password)
echo $OCPURLCON
echo $OCPURLAPI
echo $OCPADMINUSER
echo $OCPADMINPASS

### PAREI AQUI!!!
### PAREI AQUI!!!
### PAREI AQUI!!!
### PAREI AQUI!!!

echo $DIR_NFS
echo $STORAGECLASSNAME

echo "Actualizing Linux"
sudo dnf -y upgrade
sudo yum -y update

echo "Installing NFS Utils"
sudo dnf install -y nfs-utils

echo "Installing GIT"
sudo dnf install -y git
git --version

echo "Installing JQ"
sudo dnf install -y jq 
jq --version

echo "Installing YQ"
VERSION=v4.2.0
BINARY=yq_linux_amd64
wget https://github.com/mikefarah/yq/releases/download/${VERSION}/${BINARY}.tar.gz -O - |\
  tar xz && mv ${BINARY} /usr/bin/yq
yq --version

echo "Installing Docker"
sudo yum remove docker                   docker-client                   docker-client-latest                    docker-common                   docker-latest                   docker-latest-logrotate                   docker-logrotate                   docker-engine -y
sudo yum install -y yum-utils
sudo yum-config-manager -y --add-repo     https://download.docker.com/linux/centos/docker-ce.repo
sudo yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo systemctl start docker
sudo systemctl enable docker

echo "Testing Docker installation"
sudo docker run hello-world
docker ps
docker ps -all
docker images

echo "Login on Docker using cp.ico.io and IBM Entitlement Key"
echo $IBMENTITLEMENTKEY
docker login cp.icr.io --username cp --password  $IBMENTITLEMENTKEY 

echo "Creating a Secret on Openshift using IBM Entitlement Key"
echo $IBMENTITLEMENTKEY
echo $PROJECT
oc create secret docker-registry ibm-entitlement-key \
    --docker-username=cp --docker-password=$IBMENTITLEMENTKEY \
    --docker-server=cp.icr.io --namespace=$PROJECT

echo "Including this dockerconfig with IBM Entitlement Key on Openshift Configuration (for all cluster)"
oc extract secret/pull-secret -n openshift-config --keys=.dockerconfigjson --to=. --confirm
cat .dockerconfigjson
cat .dockerconfigjson | sed "s/}}}/######/g" > .dockerconfigjsontmp
cat .dockerconfigjsontmp
echo $PARMDEP
cat .dockerconfigjsontmp | sed "s/######/$PARMDEP/g" > .dockerconfigjson
cat .dockerconfigjson
jq "." .dockerconfigjson
oc set data secret/pull-secret -n openshift-config --from-file=.dockerconfigjson

echo "Waiting 30 seconds"
for i in {1..30}; do  echo "Loop time "$i;   sleep 1s; done

echo "Waiting restart of all Nodes (Masters and Workers)"
while (oc get machineconfigpool | egrep -v "True      False      False|UPDATED   UPDATING   DEGRADED"); do sleep 1 ; done

echo "Creating IBM Operator Catalog on Openshift Cluster"
echo $DIR_CP4X_INST
mkdir -p $DIR_CP4X_INST
chmod 777 $DIR_CP4X_INST
cat <<EOF >> $DIR_CP4X_INST/ibmoperator.yaml
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: ibm-operator-catalog
  namespace: openshift-marketplace
spec:
  displayName: IBM Operator Catalog
  image: 'icr.io/cpopen/ibm-operator-catalog:latest'
  publisher: IBM
  sourceType: grpc
  updateStrategy:
    registryPoll:
      interval: 45m
EOF
oc apply -f $DIR_CP4X_INST/ibmoperator.yaml

echo "Creating IBM Operator Group on Openshift Cluster"
echo $DIR_CP4X_INST
mkdir -p $DIR_CP4X_INST
chmod 777 $DIR_CP4X_INST
cat <<EOF >> $DIR_CP4X_INST/ibmoperatorgroup.yaml
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: ibm-integration-operatorgroup
spec:
  targetNamespaces:
  - $PROJECT
EOF
oc apply -f $DIR_CP4X_INST/ibmoperatorgroup.yaml

echo "Creating Storage Class (rook-ceph-fs and rook-ceph-block) on Openshift Cluster"
git clone --single-branch --branch v1.10.4 https://github.com/rook/rook.git
cd rook/deploy/examples
oc create -f common.yaml
oc create -f crds.yaml
oc create -f operator-openshift.yaml
oc -n rook-ceph set image deploy/rook-ceph-operator rook-ceph-operator=rook/ceph:v1.10.4
oc create -f cluster.yaml
oc project rook-ceph
oc create -f ./csi/rbd/storageclass.yaml
oc create -f filesystem.yaml
oc create -f ./csi/cephfs/storageclass.yaml
oc patch storageclass rook-cephfs -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"false"}}}'
oc create -f toolbox.yaml
oc patch storageclass rook-ceph-block -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'


cat <<EOF >> $DIR_CP4X_INST/ibmintranetoauth.yaml
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
    - mappingMethod: claim
      name: IBM W3 intranet login
      type: LDAP
      ldap:
        attributes:
          email:
            - emailAddress
          id:
            - dn
          name:
            - cn
          preferredUsername:
            - emailAddress
        insecure: false
        url: "ldaps://bluepages.ibm.com:636/ou=bluepages,o=ibm.com?emailAddress?sub?(objectclass=ePerson)"
EOF
oc apply -f $DIR_CP4X_INST/ibmintranetoauth.yaml
        
echo "###### FINISH - ZZZ SCRIPT - PREPARING OPENSHIFT (OCP) ON FYRE TO INSTALL CLOUD PAK FOR X (CP4X)"
export STOP=$(date)
echo "###### START: "$START " - STOP: "$STOP" ###### "

echo "Contact: alexandre.zanetti@br.ibm.com"
