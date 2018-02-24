FROM python:alpine3.7
MAINTAINER leo.lou@gov.bc.ca

ARG dep="libstdc++ curl wget ca-certificates freetype-dev libpng-dev lapack openblas git"
ARG tbc="alpine-sdk gfortran build-base python3-dev openblas-dev"
ENV numpy_WHL=https://pypi.python.org/packages/59/e2/57c1a6af4ff0ac095dd68b12bf07771813dbf401faf1b97f5fc0cb963647/numpy-1.13.1-cp36-cp36m-manylinux1_x86_64.whl \
    panda_WHL=https://pypi.python.org/packages/fe/6f/5733658857dffb998afa2120027171c263384ada0487a969e5ecd5bf9ac9/pandas-0.20.3-cp36-cp36m-manylinux1_x86_64.whl

#Patch GLIBC
RUN \
   apk add --no-cache --update $dep && \
   apk add --virtual=.dev $tbc && \
   ln -s /usr/include/locale.h /usr/include/xlocale.h

COPY runme /bin/runme

RUN mkdir /app \
 && chmod 755 /bin/runme \
 && git clone https://gogs.data.gov.bc.ca/leolou/data-linking-ui /tmp/ui/ \
 && git clone https://gogs.data.gov.bc.ca/leolou/data-linking /tmp/dl \
 && wget -O /tmp/numpy-1.13.1-cp36-cp36m-manylinux1_x86_64.whl $numpy_WHL \
 && wget -O /tmp/pandas-0.20.3-cp36-cp36m-manylinux1_x86_64.whl $panda_WHL \
 && pip install /tmp/numpy-1.13.1-cp36-cp36m-manylinux1_x86_64.whl \
 && pip install /tmp/pandas-0.20.3-cp36-cp36m-manylinux1_x86_64.whl \
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
