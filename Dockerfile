FROM ubuntu:16.10

MAINTAINER Sateesh H

# Install required packages and remove the apt packages cache when done.
RUN apt-get update && apt-get install -y \
	git \
	vim \
	python \
	build-essential python \
	python-dev \
	python-setuptools \
	libpq-dev \
  && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/log/uwsgi
RUN easy_install pip

# install uwsgi now because it takes a little while
RUN CC=gcc python -m pip install uwsgi

# COPY requirements.txt and RUN pip install BEFORE adding the rest of your code, this will cause Docker's caching mechanism
# to prevent re-installinig (all your) dependencies when you made a change a line or two in your app. 

COPY requirements.txt /home/docker/code/
RUN python -m pip install -r /home/docker/code/requirements.txt

# add (the rest of) our code
COPY . /home/docker/code/

# install django, normally you would remove this step because your project would already
# be installed in the code/app/ directory
RUN chown -R www-data:www-data /home/docker/code/
RUN chmod -R 664 /home/docker/code/
# RUN /home/docker/code/wsgi.py startproject website /home/docker/code/ 

# Cleanup to reduce image size
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists/*
RUN rm -rf /tmp/pip-build-root

# I want the web application running in the container to be accessible from
# the outside. We're exposing a REST API to control and monitor the scan worker
EXPOSE 9082 

# RUN supervisord with our configuration so that the daemons are started
CMD ["/usr/local/bin/uwsgi", "--ini", "/home/docker/code/uwsgi.ini"]
