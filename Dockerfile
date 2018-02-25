FROM python:alpine3.7
MAINTAINER leo.lou@gov.bc.ca

ARG dep="libstdc++ curl wget ca-certificates lapack openblas git freetype lcms2 libjpeg-turbo libwebp musl openjpeg tiff zlib libxslt libxml2"
ARG tbc="alpine-sdk linux-headers gfortran build-base python3-dev openblas-dev libffi-dev freetype-dev libpng-dev jpeg-dev zlib-dev lcms2-dev openjpeg-dev tiff-dev py3-tz py3-dateutil libxslt-dev libxml2-dev"

ENV NUMPY_VER=1.13.1 \
    PANDA_VER=0.20.3
ENV numpy_SRC=https://github.com/numpy/numpy/releases/download/v$NUMPY_VER/numpy-$NUMPY_VER.tar.gz \
    panda_SRC=https://github.com/pandas-dev/pandas/archive/v$PANDA_VER.tar.gz

RUN \
   apk add --no-cache --update $dep && \
   apk add --no-cache --virtual=.dev $tbc && \
   echo "@leg http://dl-4.alpinelinux.org/alpine/v3.4/main" >> /etc/apk/repositories && \
   apk add --no-cache postgresql-dev@leg && \
   ln -s /usr/include/locale.h /usr/include/xlocale.h

COPY runme /bin/runme

RUN mkdir /app \
 && chmod 755 /bin/runme \
 && git clone https://gogs.data.gov.bc.ca/leolou/data-linking-ui /tmp/ui/ \
 && git clone https://gogs.data.gov.bc.ca/leolou/data-linking /tmp/dl \
 && export WHEELHOUSE="/tmp/.wheelhouse" \
 && export PIP_FIND_LINKS="file://${WHEELHOUSE}" \
 && export PIP_WHEEL_DIR="${WHEELHOUSE}" \
 && pip wheel cython && pip install cython \
 && wget -O /tmp/numpysrc $numpy_SRC && tar xvf /tmp/numpysrc -C /tmp \
 && wget -O /tmp/pandasrc $panda_SRC && tar xvf /tmp/pandasrc -C /tmp \
 && export NPROC=$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1) \
 && cd /tmp/numpy-$NUMPY_VER && cp site.cfg.example site.cfg \
 && echo -en "\n[openblas]\nlibraries = openblas\nlibrary_dirs = /usr/lib\ninclude_dirs = /usr/include\n" >> site.cfg \
 && python setup.py build -j ${NPROC} --fcompiler=gfortran install \
 && cd /tmp/pandas-$PANDA_VER && python setup.py build -j ${NPROC} install \
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
