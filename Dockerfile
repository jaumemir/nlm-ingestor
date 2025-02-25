# syntax=docker/dockerfile:experimental

FROM python:3.11-bookworm

# Create a new user and group with specific UID that needs to be set in Deployment
RUN adduser --uid 1000650000 --gid 0 appuser --home /home/appuser --gecos appuser --disabled-password

RUN apt-get update && apt-get -y --no-install-recommends install libgomp1
ENV APP_HOME /app

# install Java
RUN mkdir -p /usr/share/man/man1 && \
  apt-get update -y && \
  apt-get install -y openjdk-17-jre-headless

# install essential packages
RUN apt-get install -y \
  libxml2-dev libxslt-dev \
  build-essential libmagic-dev

# install tesseract
RUN apt-get install -y \
  tesseract-ocr \
  lsb-release \
  && echo "deb https://notesalexp.org/tesseract-ocr5/$(lsb_release -cs)/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/notesalexp.list > /dev/null \
  && apt-get update -oAcquire::AllowInsecureRepositories=true \
  && apt-get install notesalexp-keyring -oAcquire::AllowInsecureRepositories=true -y --allow-unauthenticated \
  && apt-get update \
  && apt-get install -y \
  tesseract-ocr libtesseract-dev \
  && wget -P /usr/share/tesseract-ocr/5/tessdata/ https://github.com/tesseract-ocr/tessdata/raw/main/eng.traineddata

RUN apt-get install unzip -y && \
  apt-get install git -y && \
  apt-get autoremove -y

WORKDIR ${APP_HOME}   
COPY . ./
RUN pip install --upgrade pip setuptools
RUN apt-get install -y libmagic1

# Set non-root ownership 
RUN chown -R appuser:root ${APP_HOME} 
RUN chown -R appuser:root /home/appuser
USER appuser
RUN mkdir -p -m 0700 ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts

RUN pip install -r requirements.txt
RUN python -m nltk.downloader stopwords
RUN python -m nltk.downloader punkt
RUN chmod +x run.sh

CMD ./run.sh    
