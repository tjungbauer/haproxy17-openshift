# Haproxy with lua on centos:latest

Thanks to https://hub.docker.com/_/haproxy/ for the base docker file.  
I have now switched from debian based image to a RedHat based one because there 
is the pcre jit compiler included

The size of the image is ~67.1 MB

This haproxy image is based on version 1.7 which have the possibility to resolve 
DNS-Names. Lua 5.3.4 is also enabled in this Image

In case the env var `DNS_SRV001` and `DNS_SRV002` is not set the 
`container-entrypoint.sh` will try to get it from the running container.

When you set the env var `CONFIG_FILE` the haproxy will use this instead of the 
build in one.

# Docker

to build run this on a rhel machine.

```
docker build --tag me2digital/haproxy17 https://gitlab.com/aleks001/haproxy17-centos.git
```

for a shell run this.

```
$ docker run --rm -it --name my-running-haproxy \
    -e TZ=Europe/Vienna \
    -e STATS_PORT=1999 \
    -e STATS_USER=aaa \
    -e STATS_PASSWORD=bbb \
    -e SERVICE_TCP_PORT=13443 \
    -e SERVICE_NAME=test-haproxy \
    -e SERVICE_DEST_PORT=8080 \
    -e SERVICE_DEST='1.2.3.4;5.6.7.8;80.44.22.7' \
    my-haproxy /bin/bash
```

In the container you can see that ;-)

```
/usr/local/sbin/haproxy -vv
HA-Proxy version 1.7. 2017/07/07
Copyright 2000-2017 Willy Tarreau <willy@haproxy.org>

Build options :
  TARGET  = linux2628
  CPU     = generic
  CC      = gcc
  CFLAGS  = -O2 -g -fno-strict-aliasing -Wdeclaration-after-statement -fwrapv
  OPTIONS = USE_LINUX_SPLICE=1 USE_GETADDRINFO=1 USE_ZLIB=1 USE_REGPARM=1 USE_OPENSSL=1 USE_LUA=1 USE_PCRE=1 USE_PCRE_JIT=1 USE_TFO=1

Default settings :
  maxconn = 2000, bufsize = 16384, maxrewrite = 1024, maxpollevents = 200

Encrypted password support via crypt(3): yes
Built with zlib version : 1.2.7
Running on zlib version : 1.2.7
Compression algorithms supported : identity("identity"), deflate("deflate"), raw-deflate("deflate"), gzip("gzip")
Built with OpenSSL version : OpenSSL 1.0.1e-fips 11 Feb 2013
Running on OpenSSL version : OpenSSL 1.0.1e-fips 11 Feb 2013
OpenSSL library supports TLS extensions : yes
OpenSSL library supports SNI : yes
OpenSSL library supports prefer-server-ciphers : yes
Built with PCRE version : 8.32 2012-11-30
Running on PCRE version : 8.32 2012-11-30
PCRE library supports JIT : yes
Built with Lua version : Lua 5.3.4
Built with transparent proxy support using: IP_TRANSPARENT IPV6_TRANSPARENT IP_FREEBIND

Available polling systems :
      epoll : pref=300,  test result OK
       poll : pref=200,  test result OK
     select : pref=150,  test result OK
Total: 3 (3 usable), will use epoll.

Available filters :
        [COMP] compression
        [TRACE] trace
        [SPOE] spoe
```

**that's cool ;-)**

# OpenShift

```
# oc new-app test-haproxy

# oc process -f https://gitlab.com/aleks001/haproxy17-centos/raw/master/haproxy-osev3.yaml \
    -p PROXY_SERVICE=test-scraper \
    -p SERVICE_NAME=tst-scr-svc \
    -p SERVICE_TCP_PORT=8443 \
    -p SERVICE_DEST_PORT=443 \
    -p SERVICE_DEST=www.google.com \
    | oc create -f -
deploymentconfig "test-scraper" created
service "test-scraper" created
service "haproxy-exporter" created
route "test-scraper" created

# oc get route
```

```
oc get pods  
```
To get the haproxy logs you must select the socklog container  
oc logs -f -c ng-socklog `<YOUR_POD>`

a log enty looks like this.

```
[al@localhost haproxy]$ oc logs -f -c hx-socklog haproxy-test-5-6yiyp
listening on 0.0.0.0:8514, starting.
10.1.4.1: local0.notice: Feb 28 10:08:54 haproxy[1]: Proxy http-in started.
10.1.4.1: local0.notice: Feb 28 10:08:54 haproxy[1]: Proxy google started.
10.1.4.1: local0.info: Feb 28 10:11:40 haproxy[1]: Connect from 10.1.2.1:43700 to 10.1.4.77:8080 (http-in/HTTP)
```

# TODOs for a real setup
- clone this repo
- copy your config and adopt it to the Openshift setup
- I'm sure there are lot more TODOs ;-)
