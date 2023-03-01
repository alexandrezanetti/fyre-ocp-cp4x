# Preparando o cluster Openshift (OCP) no ambiente Fyre para Cloud Pak (CP4x) e demais produtos / Preparing  Openshift (OCP) cluster on Fyre environment for Cloud Pak (CP4x) and beyond

This git is part of  instructions available on https://w3.ibm.com/w3publisher/preparing-fyre-for-cloud-pak-cp4x

#### 1. Entrar no Bastion do cluster OCP através de terminal (SSH) / Open Bastion of OCP cluster using terminal SSH
> Lembre-se que precisará das informações abaixo/ Note that you will use the informations below:<br>
> - Bastion IP Publico / Bastion public IP<br>
> - Entitlement Key /  Entitlement Key<br>
> - Sua senha Root / Root Password<br>

#### 2. Instalar o GIT no bastion / Instal GIT on Bastion:
> sudo dnf install -y git<br>
> git --version

#### 3. Baixar o script / Clone git with scripts
> git clone https://github.com/alexandrezanetti/turbonomic.git

#### 4. Se tiver interesse, visualizar o conteúdo do Script / Look the content
> cat /root/turbonomic/t8c-certified-operator.yaml<br>
> cat /root/turbonomic/t8c-certified-sub.yaml

#### 5. Criar o novo arquivo/script que será ajustado / create a new script to be changed
> touch /root/turbonomic/t8c-certified-operator_OK.yaml<br>
> touch /root/turbonomic/t8c-certified-sub_OK.yaml<br>
> chmod 777 /root/turbonomic/t8c-certified-operator_OK.yaml<br>
> chmod 777 /root/turbonomic/t8c-certified-sub_OK.yaml

#### 6. Muito importante: Setar estas variáveis / Must important! Define project name and set your IBM Entitlement Key
> PROJECT=turbomonic<br>
> IBMENTITLEMENTKEY=???<br>
> echo $PROJECT<br>
> echo $IBMENTITLEMENTKEY

#### 7. Ajustar o arquivo com Projeto/EntitlementKey / Run the command below to adjust Project and EntitlementKey
> cat /root/turbonomic/t8c-certified-sub.yaml | sed "s/{###PROVIDE_YOUR_PROJECT_NAMESPACE_CP4X_HERE###}/$PROJECT/g" >/root/turbonomic/t8c-certified-sub_OK.yaml<br>
> cat /root/turbonomic/t8c-certified-operator.yaml | sed "s/{###PROVIDE_YOUR_PROJECT_NAMESPACE_CP4X_HERE###}/$PROJECT/g" >/root/turbonomic/t8c-certified-operator_OK.yaml

#### 8. Execute o script / And finally, run the script
> oc apply -f /root/turbonomic/t8c-certified-operator_OK.yaml<br>
> oc apply -f /root/turbonomic/t8c-certified-sub_OK.yaml

#### 9. E finalmente, acompanhe o pod ser restatado
oc get pods -n openshift-marketplace -w | grep operators

