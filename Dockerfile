FROM python:alpine3.7
MAINTAINER leo.lou@gov.bc.ca

ARG dep="libstdc++ curl wget ca-certificates freetype-dev libpng-dev lapack openblas git"
ARG tbc="alpine-sdk gfortran build-base python3-dev openblas-dev"
ENV numpy_WHL=https://pypi.python.org/packages/b9/35/dfe4ea1ac0df18168939841c119a320745aee1f45dd74c2e1477a383d330/numpy-1.13.1-cp36-cp36m-manylinux1_i686.whl \
    panda_WHL=https://pypi.python.org/packages/91/f3/f5268fe395471a0e9686821477af5297655f437782cccbc43e41480a2bd8/pandas-0.20.3-cp36-cp36m-manylinux1_i686.whl

RUN \
   apk add --no-cache --update $dep && \
   apk add --virtual=.dev $tbc && \
   ln -s /usr/include/locale.h /usr/include/xlocale.h

COPY runme /bin/runme

RUN mkdir /app \
 && chmod 755 /bin/runme \
 && git clone https://gogs.data.gov.bc.ca/leolou/data-linking-ui /tmp/ui/ \
 && git clone https://gogs.data.gov.bc.ca/leolou/data-linking /tmp/dl \
 && wget -O /tmp/numpy-1.13.1-cp36-cp36m-manylinux1_i686.whl $numpy_WHL \
 && wget -O /tmp/pandas-0.20.3-cp36-cp36m-manylinux1_i686.whl $panda_WHL \
 && pip install /tmp/numpy*.whl \
 && pip install /tmp/pandas*.whl \
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
