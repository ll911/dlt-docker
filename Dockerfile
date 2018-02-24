FROM alpine:latest
MAINTAINER leo.lou@gov.bc.ca

RUN apk update \
&& apk add \
    ca-certificates \
    libstdc++ \
    libgfortran \
    python3 \
&& apk add --virtual=build_dependencies \
    gfortran \
    g++ \
    make \
    python3-dev \
&& ln -s /usr/include/locale.h /usr/include/xlocale.h \
&& mkdir -p /tmp/build \
&& cd /tmp/build/ \
&& wget http://www.netlib.org/blas/blas-3.6.0.tgz \
&& wget http://www.netlib.org/lapack/lapack-3.6.1.tgz \
&& tar xzf blas-3.6.0.tgz \
&& tar xzf lapack-3.6.1.tgz \
&& cd /tmp/build/BLAS-3.6.0/ \
&& gfortran -O3 -std=legacy -m64 -fno-second-underscore -fPIC -c *.f \
&& ar r libfblas.a *.o \
&& ranlib libfblas.a \
&& mv libfblas.a /tmp/build/. \
&& cd /tmp/build/lapack-3.6.1/ \
&& sed -e "s/frecursive/fPIC/g" -e "s/ \.\.\// /g" -e "s/^CBLASLIB/\#CBLASLIB/g" make.inc.example > make.inc \
&& make lapacklib \
&& make clean \
&& mv liblapack.a /tmp/build/. \
&& cd / \
&& export BLAS=/tmp/build/libfblas.a \
&& export LAPACK=/tmp/build/liblapack.a

COPY runme /bin/runme

RUN mkdir /app \
 && chmod 755 /bin/runme \
 && git clone $dlt_web /tmp/ui/ \
 && git clone $dlt_core /tmp/dl \
 && python3 -m pip install --no-cache-dir numpy==1.13.1 scipy pandas==0.20.3 matplotlib \
 && python3 -m pip install -r /tmp/ui/linkage-worker/link-server/requirements.txt \
 && python3 -m pip install -r /tmp/dl/requirements/base.txt \
 && cp -r /tmp/ui/web-app /app/ \
 && python3 -m pip install -r /app/web-app/requirements/base.txt \
 && python3 -m pip install django-debug-toolbar==1.6 django-extensions==1.7.5 \
 && python3 -m pip install -r /app/web-app/requirements/${DAPPENV}.txt \
 && mv /tmp/ui/linkage-worker/link-server /app/linkage-worker \
 && mv /tmp/dl /app/linkage-worker/lib \
 && python3 -m pip install -e /app/linkage-worker/lib/cdi-linking \
 && python3 -m pip install -e /app/linkage-worker/lib/linking_ext \
 && rm -rf /tmp/*
 
RUN adduser -S 1001
RUN chown -R 1001:0 /app && chmod -R 770 /app

USER 1001
EXPOSE 8080
CMD ["runme"] 
