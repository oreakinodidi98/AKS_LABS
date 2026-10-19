# Node image upgrade

How to perform a node image upgrade in an AKS cluster

new versions contain security patches for tools used inside the noods
recommended to upgrade to stay compliant with security
rolling upgrade 1 by one 

kubernetes releases a new minor version each 4 month. 
AKS tries to keep up to date by having a preview available 1-2 months later
then the GA version 1-2 months later
After tat the GA version is suppored fro 12 months
AKS only supports 3 latest GA versions 
so cluster admin need to upgrade at least 1a yesr to stay supported

view with 
az aks get-versions -l (region) -o table