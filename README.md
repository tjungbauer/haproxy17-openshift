# Haproxy with lua on centos:latest

Fork of: https://gitlab.com/aleks001/haproxy17-centos
Thankfully using the templates.... red above link for original readme.

Mods:
- fixed for OpenShift 4
- created separate haproxy image, some minor changes have been done in deployment shell script
- added configmap for basic variables

# Deploy in OpenShift

```
# oc new-project test-haproxy

# oc process -f https://raw.githubusercontent.com/tjungbauer/haproxy17-openshift/master/haproxy-osev4.yaml \
    -p PROXY_SERVICE=test-scraper \
    -p SERVICE_NAME=tst-scr-svc \
    -p SERVICE_TCP_PORT=8443 \
    -p SERVICE_DEST_PORT=443 \
    -p SERVICE_DEST=www.google.at:443;www.google.com:443 \
    | oc create -f -

TIP: If SERVICE_DEST does not contain ":" (no port given), then SERVICE_DEST_PORT will be used.
