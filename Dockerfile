FROM python:alpine3.7
MAINTAINER leo.lou@gov.bc.ca

ARG dep="libstdc++ curl wget ca-certificates freetype-dev libpng-dev lapack openblas git"
ARG tbc="alpine-sdk gfortran build-base openblas-dev"
ENV numpy_SRC=https://pypi.python.org/packages/c0/3a/40967d9f5675fbb097ffec170f59c2ba19fc96373e73ad47c2cae9a30aed/numpy-1.13.1.zip \
    panda_SRC=https://pypi.python.org/packages/ee/aa/90c06f249cf4408fa75135ad0df7d64c09cf74c9870733862491ed5f3a50/pandas-0.20.3.tar.gz

RUN \
   apk add --no-cache --update $dep && \
   apk add --virtual=.dev $tbc && \
   ln -s /usr/include/locale.h /usr/include/xlocale.h

COPY runme /bin/runme

RUN mkdir /app \
 && chmod 755 /bin/runme \
 && git clone https://gogs.data.gov.bc.ca/leolou/data-linking-ui /tmp/ui/ \
 && git clone https://gogs.data.gov.bc.ca/leolou/data-linking /tmp/dl \
 && pip wheel numpy==1.13.1 \
 && pip install numpy==1.13.1
 && pip wheel pandas==0.20.3 \
 && pip install pandas==0.20.3
 && pip install -r /tmp/ui/linkage-worker/link-server/requirements.txt \
 && pip install -r /tmp/dl/requirements/base.txt \
 && cp -r /tmp/ui/web-app /app/ \
 && pip install -r /app/web-app/requirements/base.txt \
 && pip install django-debug-toolbar==1.6 django-extensions==1.7.5 \
 && pip install -r /app/web-app/requirements/${DAPPENV}.txt \
 && mv /tmp/ui/linkage-worker/link-server /app/linkage-worker \
 && mv /tmp/dl /app/linkage-worker/lib \
 && pip install -e /app/linkage-worker/lib/cdi-linking \
 && pip install -e /app/linkage-worker/lib/linking_ext

RUN \
 && apk del --purge -r .dev \
 && rm -rf /tmp/* \
 && rm -rf /var/cache/apk/*


RUN adduser -S 1001
RUN chown -R 1001:0 /app && chmod -R 770 /app

USER 1001
EXPOSE 8080
CMD ["runme"]
