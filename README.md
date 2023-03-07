# Preparando o cluster Openshift (OCP) no ambiente Fyre para Cloud Pak (CP4x) e demais produtos / Preparing  Openshift (OCP) cluster on Fyre environment for Cloud Pak (CP4x) and beyond

This git is part of  instructions available on https://w3.ibm.com/w3publisher/preparing-fyre-for-cloud-pak-cp4x

#### 1. Entrar no Bastion do cluster OCP através de terminal (SSH) / Open Bastion of OCP cluster using terminal SSH
> Lembre-se que precisará das informações abaixo/ Note that you will use the informations below:<br>
> - Bastion IP Publico / Bastion public IP<br>
> - Entitlement Key /  Entitlement Key<br>
> - Sua senha Root / Root Password<br>

#### 2. Instalar o GIT no bastion / Instal GIT on Bastion:
```
dnf install -y git
```

#### 3. Baixar o script / Clone git with scripts
```
git clone https://github.com/alexandrezanetti/fyre-ocp-cp4x.git
```

#### 4. E finalmente, execute o script / And finally, run the script
Preencha os conteudos abaixo {###PROVIDE_YOUR_PROJECT_NAMESPACE_CP4X_HERE###} e {###PROVIDE_YOUR_IBM_ENTITLEMENT_KEY_HERE###} no comando abaixo:
```
export PROJECT={###PROVIDE_YOUR_PROJECT_NAMESPACE_CP4X_HERE###} ; export IBMENTITLEMENTKEY=$(echo "{###PROVIDE_YOUR_IBM_ENTITLEMENT_KEY_HERE###}") ; chmod a+x /root/fyre-ocp-cp4x/zzzPreparation.sh ; /root/fyre-ocp-cp4x/./zzzPreparation.sh
```

#### Observação! No final mostrará o tempo de início e o final da execução. / At the end you will see the time lapsed from this execution.
