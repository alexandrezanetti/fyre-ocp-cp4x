# fyre-ocp-cp4x
Preparation Openshift (OCP) on Fyre for Cloud Pak 4 x (CP4x)

This git is part of  instructions available on https://w3.ibm.com/w3publisher/preparing-fyre-for-cloud-pak-cp4x

(*1) Entrar no Bastion do cluster OCP através de terminal (SSH) / Open Bastion of OCP cluster using terminal SSH

(*2) Instalar o GIT no bastion / Instal GIT on Bastion:
sudo dnf install -y git
git --version

(*3) Baixar o script / Clone git with scripts
git clone https://github.com/alexandrezanetti/fyre-ocp-cp4x.git

(*4) Se tiver interesse, visualizar o conteúdo do Script / Look the content
cat /root/fyre-ocp-cp4x/zzzPreparation.sh

(*5) Criar o novo arquivo/script que será ajustado / create a new script to be changed
touch /root/fyre-ocp-cp4x/zzzPreparationOK.sh
chmod 777 /root/fyre-ocp-cp4x/zzzPreparationOK.sh

(*6) Muito importante: Setar estas variáveis / Must important! Define project name and set your IBM Entitlement Key
PROJECT=CP4?
IBMENTITLEMENTKEY=???
echo $PROJECT
echo $IBMENTITLEMENTKEY

(*7) Ajustar o arquivo com Projeto/EntitlementKey / Run the command below to adjust Project and EntitlementKey
cat /root/fyre-ocp-cp4x/zzzPreparation.sh | sed "s/={###PROVIDE_YOUR_IBM_ENTITLEMENT_KEY_HERE###}/=$IBMENTITLEMENTKEY/g" | sed "s/={###PROVIDE_YOUR_PROJECT_NAMESPACE_CP4X_HERE###}/=$PROJECT/g" >/root/fyre-ocp-cp4x/zzzPreparationOK.sh

(*8) E finalmente, execute o script / And finally, run the script
/root/fyre-ocp-cp4x/./zzzPreparationOK.sh

Observação! No final mostrará o tempo de início e o final da execução. / At the end you will see the time lapsed from this execution.
