#
#            - [ BROAD'16 ] -
#
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
	vim 			\
	python-yaml		\
	tree			\
	python3-pip

WORKDIR /usr/local/src
RUN git clone https://github.com/s3fs-fuse/s3fs-fuse.git
WORKDIR /usr/local/src/s3fs-fuse
RUN ./autogen.sh
RUN ./configure
RUN make
RUN make install

#RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg  add - && apt-get update -y && apt-get install google-cloud-sdk -y


RUN mkdir -p /usr/local/src/workspace/illum
RUN mkdir -p /usr/local/src/workspace/audit
RUN mkdir -p /usr/local/src/workspace/analysis
RUN mkdir -p /usr/local/src/workspace/backend
RUN mkdir -p /usr/local/src/workspace/batchfiles
RUN mkdir -p /usr/local/src/workspace/github
RUN mkdir -p /usr/local/src/workspace/images
RUN mkdir -p /usr/local/src/workspace/load_data_csv

RUN mkdir -p /usr/local/src/workspace/log/create_batch_files_analysis
RUN mkdir -p /usr/local/src/workspace/log/create_batch_files_illum
RUN mkdir -p /usr/local/src/workspace/log/create_csv_from_xml
RUN mkdir -p /usr/local/src/workspace/log/collate

RUN mkdir -p /usr/local/src/workspace/software
RUN mkdir -p /usr/local/src/workspace/status
RUN mkdir -p /usr/local/src/workspace/pipelines

COPY task_bundler.py /usr/local/src/workspace/software/

WORKDIR /usr/local/src/workspace/software
RUN git clone https://github.com/broadinstitute/pe2loaddata.git
RUN git clone https://github.com/broadinstitute/cytominer_scripts.git
RUN git clone https://github.com/broadinstitute/cellpainting_scripts.git

WORKDIR /usr/local/src/workspace/github
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

RUN \
	pip install awscli 

RUN \
	pip install boto3

RUN \
   pip install IPython==5.0

RUN \
	pip3 install cytominer-database

# Install GCP 

#RUN \
#  pip install google-cloud-storage 

# SETUP NEW ENTRYPOINT

RUN mkdir -p /home/ubuntu/

ENTRYPOINT []
#CMD [""]


