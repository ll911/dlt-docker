FROM alpine:latest
MAINTAINER leo.lou@gov.bc.ca

ENV LANG=C.UTF-8 \
    GLIBC_VERSION=2.27-r0

ARG dep="alpine-sdk gfortran python3 python3-dev py3-pip build-base libstdc++ curl wget ca-certificates freetype-dev libpng-dev openblas-dev git"
 
#Patch GLIBC
RUN apk upgrade --update && apk add --update $dep && \
    for pkg in glibc-${GLIBC_VERSION} glibc-bin-${GLIBC_VERSION} glibc-i18n-${GLIBC_VERSION}; do curl -sSL https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/${pkg}.apk -o /tmp/${pkg}.apk -o /tmp/${pkg}.apk; done && \
    apk add --allow-untrusted /tmp/*.apk && \
    rm -v /tmp/*.apk && \
    ( /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true ) && \
    echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh && \
    /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib
    
RUN apk --no-cache --update-cache add $dep
RUN ln -s /usr/include/locale.h /usr/include/xlocale.h

COPY runme /bin/runme

RUN mkdir /app \
 && chmod 755 /bin/runme \
 && git clone $dlt_web /tmp/ui/ \
 && git clone $dlt_core /tmp/dl \
 && pip3 install -r /tmp/ui/linkage-worker/link-server/requirements.txt \
 && pip3 install -r /tmp/dl/requirements/base.txt \
 && cp -r /tmp/ui/web-app /app/ \
 && pip3 install -r /app/web-app/requirements/base.txt \
 && pip3 install django-debug-toolbar==1.6 django-extensions==1.7.5 \
 && pip3 install -r /app/web-app/requirements/${DAPPENV}.txt \
 && mv /tmp/ui/linkage-worker/link-server /app/linkage-worker \
 && mv /tmp/dl /app/linkage-worker/lib \
 && pip3 install -e /app/linkage-worker/lib/cdi-linking \
 && pip3 install -e /app/linkage-worker/lib/linking_ext \
 && rm -rf /tmp/*
 
RUN adduser -S 1001
RUN chown -R 1001:0 /app && chmod -R 770 /app

USER 1001
EXPOSE 8080
CMD ["runme"] 
