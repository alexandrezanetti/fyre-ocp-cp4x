#!/bin/bash
clear
echo "Check your IBM Entitlement Key - https://myibm.ibm.com/products-services/containerlibrary" 
echo $IBMENTITLEMENTKEY
if [ ${IBMENTITLEMENTKEY} = "{###PROVIDE_YOUR_IBM_ENTITLEMENT_KEY_HERE###}" ]; then echo "Please provide your IBM Entitlement Key - Check https://myibm.ibm.com/products-services/containerlibrary"; exit 999; fi

echo "Check your Project (Namespace) name" 
if [ ${PROJECT} = "{###PROVIDE_YOUR_PROJECT_NAMESPACE_CP4X_HERE###}" ]; then echo "Please provide your Project/Namespace (CP4x)"; exit 999; fi
PROJECT=$(echo $PROJECT | tr A-Z a-z)
echo $PROJECT
oc new-project $PROJECT
oc project $PROJECT

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
#if [ ${email} = "{###INFORME SEU EMAIL###}" ]; then echo "Please provide your Email"; exit 999; fi

echo "###### START - ZZZ SCRIPT - PREPARING OPENSHIFT (OCP) ON FYRE TO INSTALL CLOUD PAK FOR X (CP4X)"
export START=$(date)

echo "Creating the installation directory - in general /tmp/cp4x" 
export DIR_CP4X_INST=/tmp/CP4X
echo $DIR_CP4X_RWX
mkdir -p $DIR_CP4X_INST
chmod a+x $DIR_CP4X_INST

echo "Creating an Oauth for W3"
cat <<EOF >> $DIR_CP4X_INST/ibmintranetoauth.yaml
apiVersion: config.openshift.io/v1
kind: OAuth
metadata:
  name: cluster
spec:
  identityProviders:
    - mappingMethod: claim
      name: IBM W3 intranet
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

echo "Install ldapsearch (OpenLdap Client)"
dnf install -y openldap-clients

manager=$(ldapsearch -x -H ldaps://bluepages.ibm.com:636 -b "c=br,ou=bluepages,o=ibm.com" -s sub "(emailAddress=${email})" | grep "managerSerialNumber: " | cut -c22-27)
echo $manager

for i in $(ldapsearch -x -LLL -H ldaps://bluepages.ibm.com:636 -b "ou=bluepages,o=ibm.com" "(managerSerialNumber=${manager})" dn | grep "dn" | cut -c5-); do chave=$(echo $i | base64 | cut -c1-55); echo "${i};IBM W3 Intranet:${chave}"; done > matricula.txt
cat matricula.txt

ldapsearch -x -LLL -H ldaps://bluepages.ibm.com:636 -b "ou=bluepages,o=ibm.com" "(managerSerialNumber=${manager})" dn preferredIdentity | sed -z 's/\n/\;/g' | sed 's/\;\;/\n/g' | sed 's/preferredIdentity\: //g' > email.txt
cat email.txt

ldapsearch -x -LLL -H ldaps://bluepages.ibm.com:636 -b "ou=bluepages,o=ibm.com" "(managerSerialNumber=${manager})" dn hrFirstName hrLastName | sed -z 's/\n/\;/g' | sed 's/\;\;/\n/g' | sed 's/hrFirstName\: //g' | sed 's/\;hrLastName\: / /g' > nome.txt
cat nome.txt

while IFS= read -r line #|| [ -n ${line} ]
do
	echo "line: ${line}"
        matricula=$(echo ${line} | cut -c5-13)
        export identity=$(echo "${line}" | grep -i ${matricula} | cut -d";" -f2)
        export email=$(cat ./email.txt | grep -i ${matricula} | cut -d";" -f2)
        export nome=$(cat ./nome.txt | grep -i ${matricula} | cut -d";" -f2)

        #echo "matricula: ${matricula}"
        #echo " identity: ${identity}"
        #echo "    email: ${email}"
        #echo "     nome: ${nome}"
        #echo "##############################################################################################################################"

        echo "oc create user ${email} --full-name="${nome}""
        oc create user ${email} --full-name="${nome}"
        
        echo "oc create identity "${identity}""
        oc create identity "${identity}"
        
        echo "oc create useridentitymapping "${identity}" ${email}"
        oc create useridentitymapping "${identity}" ${email}
        
        #echo "oc adm policy add-role-to-user admin ${email} -n ${PROJECT}"        
        #oc adm policy add-role-to-user admin ${email} -n ${PROJECT}
	echo "oc adm policy add-cluster-role-to-user cluster-admin admin ${email}"
	oc adm policy add-cluster-role-to-user cluster-admin admin ${email} 
	echo "##############################################################################################################################"
done < matricula.txt

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
chmod a+x $DIR_CP4X_INST
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
echo "###### FINISH - ZZZ SCRIPT - PREPARING OPENSHIFT (OCP) ON FYRE TO INSTALL CLOUD PAK FOR X (CP4X)"
export STOP=$(date)
echo "###### START: "$START " - STOP: "$STOP" ###### "

echo "Contact: alexandre.zanetti@br.ibm.com"
