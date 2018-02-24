FROM alpine:latest
MAINTAINER leo.lou@gov.bc.ca

#prepare base for numpy on alpine
ENV BLAS_VERSION=3.6.0 \
    LAPACK_VERSION=3.6.1

ARG dep="ca-certificates libstdc++ libgfortran python3"
ARG tbc="gfortran g++ make python3-dev"

RUN apk update \
&& apk add $dep
&& apk add --virtual=.dev $tbc
&& ln -s /usr/include/locale.h /usr/include/xlocale.h \
&& mkdir -p /tmp/build \
&& cd /tmp/build/ \
&& wget http://www.netlib.org/blas/blas-$BLAS_VERSION.tgz \
&& wget http://www.netlib.org/lapack/lapack-$LAPACK_VERSION.tgz \
&& tar xzf blas-$BLAS_VERSION.tgz \
&& tar xzf lapack-$LAPACK_VERSION.tgz \
&& cd /tmp/build/BLAS-$BLAS_VERSION/ \
&& gfortran -O3 -std=legacy -m64 -fno-second-underscore -fPIC -c *.f \
&& ar r libfblas.a *.o \
&& ranlib libfblas.a \
&& mv libfblas.a /tmp/build/. \
&& cd /tmp/build/lapack-$LAPACK_VERSION/ \
&& sed -e "s/frecursive/fPIC/g" -e "s/ \.\.\// /g" -e "s/^CBLASLIB/\#CBLASLIB/g" make.inc.example > make.inc \
&& make lapacklib \
&& make clean \
&& mv liblapack.a /tmp/build/. \
&& cd / \
&& export BLAS=/tmp/build/libfblas.a \
&& export LAPACK=/tmp/build/liblapack.a
#end prepare base for numpy on alpine

#dlt install
ARG apip="python3 -m pip"
COPY runme /bin/runme
RUN mkdir /app \
 && chmod 755 /bin/runme \
 && git clone $dlt_web /tmp/ui/ \
 && git clone $dlt_core /tmp/dl \
 && $apip install --no-cache-dir numpy==1.13.1 pandas==0.20.3 matplotlib \
 && $apip install -r /tmp/ui/linkage-worker/link-server/requirements.txt \
 && $apip install -r /tmp/dl/requirements/base.txt \
 && cp -r /tmp/ui/web-app /app/ \
 && $apip install -r /app/web-app/requirements/base.txt \
 && $apip install django-debug-toolbar==1.6 django-extensions==1.7.5 \
 && $apip install -r /app/web-app/requirements/${DAPPENV}.txt \
 && mv /tmp/ui/linkage-worker/link-server /app/linkage-worker \
 && mv /tmp/dl /app/linkage-worker/lib \
 && $apip install -e /app/linkage-worker/lib/cdi-linking \
 && $apip install -e /app/linkage-worker/lib/linking_ext \
 && rm -rf /tmp/*
#end of dlt install

RUN adduser -S 1001
RUN chown -R 1001:0 /app && chmod -R 770 /app

USER 1001
EXPOSE 8080
CMD ["runme"] 
