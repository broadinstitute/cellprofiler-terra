#
#            - [ BROAD'16 ] -
#
# A docker instance for accessing AWS resources
# This wraps the cellprofiler docker registry
#

FROM cellprofiler/cellprofiler:latest

# Install S3FS 

RUN apt-get -y update           && \
    apt-get -y upgrade          && \
    apt-get -y install 		\
	automake 		\
	autotools-dev 		\
	g++ 			\
	git 			\
	libcurl4-gnutls-dev 	\
	libfuse-dev 		\
	libssl-dev 		\
	libxml2-dev 		\
	make pkg-config		\
	sysstat			\
	curl            \
	tree

WORKDIR /usr/local/src
RUN git clone https://github.com/s3fs-fuse/s3fs-fuse.git
WORKDIR /usr/local/src/s3fs-fuse
RUN ./autogen.sh
RUN ./configure
RUN make
RUN make install

RUN mkdir /usr/local/src/input
RUN mkdir /usr/local/src/output

RUN mkdir -p /usr/local/src/workspace/softwear
WORKDIR /usr/local/src/workspace/softwear
RUN git clone https://github.com/broadinstitute/pe2loaddata.git
RUN git clone https://github.com/broadinstitute/cytominer_scripts.git
RUN git clone https://github.com/broadinstitute/cellpainting_scripts.git
RUN git clone https://github.com/broadinstitute/imaging-platform-pipelines.git

WORKDIR /usr/local/src
# Install FUSE 

#RUN apt-get -y install lsb-core
#RUN export GCSFUSE_REPO=gcsfuse-xenial
RUN echo "deb http://packages.cloud.google.com/apt gcsfuse-xenial main" | tee /etc/apt/sources.list.d/gcsfuse.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN cat /etc/apt/sources.list.d/gcsfuse.list
RUN apt-get -y update
RUN apt-get -y install gcsfuse

RUN \
  pip install gsutil 

# Install GCP 

RUN \
  pip install google-cloud-storage 

# SETUP NEW ENTRYPOINT

RUN mkdir -p /home/ubuntu/

ENTRYPOINT []
#CMD [""]


