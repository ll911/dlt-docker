FROM python:alpine3.7
MAINTAINER leo.lou@gov.bc.ca

ENV LANG=C.UTF-8 \
    GLIBC_VERSION=2.27-r0

ARG dep="alpine-sdk gfortran build-base libstdc++ curl wget ca-certificates freetype-dev libpng-dev lapack openblas openblas-dev git"
 
#Patch GLIBC
RUN apk upgrade --update && apk add --no-cache --update $dep && \
    ln -s /usr/include/locale.h /usr/include/xlocale.h && \
    for pkg in glibc-${GLIBC_VERSION} glibc-bin-${GLIBC_VERSION} glibc-i18n-${GLIBC_VERSION}; do curl -sSL https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/${pkg}.apk -o /tmp/${pkg}.apk -o /tmp/${pkg}.apk; done && \
    apk add --allow-untrusted /tmp/*.apk && \
    rm -v /tmp/*.apk && \
    ( /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 C.UTF-8 || true ) && \
    echo "export LANG=C.UTF-8" > /etc/profile.d/locale.sh && \
    /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib

COPY runme /bin/runme

RUN mkdir /app \
 && chmod 755 /bin/runme \
 && git clone $dlt_web /tmp/ui/ \
 && git clone $dlt_core /tmp/dl \
 && pip install -r /tmp/ui/linkage-worker/link-server/requirements.txt \
 && pip install -r /tmp/dl/requirements/base.txt \
 && cp -r /tmp/ui/web-app /app/ \
 && pip install -r /app/web-app/requirements/base.txt \
 && pip install django-debug-toolbar==1.6 django-extensions==1.7.5 \
 && pip install -r /app/web-app/requirements/${DAPPENV}.txt \
 && mv /tmp/ui/linkage-worker/link-server /app/linkage-worker \
 && mv /tmp/dl /app/linkage-worker/lib \
 && pip install -e /app/linkage-worker/lib/cdi-linking \
 && pip install -e /app/linkage-worker/lib/linking_ext \
 && rm -rf /tmp/*
 
RUN adduser -S 1001
RUN chown -R 1001:0 /app && chmod -R 770 /app

USER 1001
EXPOSE 8080
CMD ["runme"] 
