FROM ubuntu:20.04

LABEL maintainer="tolgatasci1@gmail.com"
LABEL version="1"
LABEL description="It sends traffic using the tor network."

ARG DEBIAN_FRONTEND=noninteractive

ENV TZ=Europe/Kiev
ENV CHROMEDRIVER_DIR=/chromedriver
ENV PATH=${CHROMEDRIVER_DIR}:${PATH}

# Set timezone
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install dependencies and Google Chrome
RUN apt-get update && apt-get install -y \
    gnupg2 \
    ca-certificates \
    wget \
    xvfb \
    unzip \
    curl \
    python3-pip \
    chromium-browser \
    psmisc \
    netcat \
    --no-install-recommends && \
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list && \
    apt-get update -y && \
    apt-get install -y google-chrome-stable && \
    apt-get dist-upgrade -y && \
    apt-get install -y tor tor-geoipdb torsocks && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create directory for ChromeDriver
RUN mkdir -p ${CHROMEDRIVER_DIR}

# Specify the ChromeDriver version
ENV CHROMEDRIVER_VERSION=114.0.5735.90

# Download and install ChromeDriver
RUN wget -q --continue -P ${CHROMEDRIVER_DIR} "https://chromedriver.storage.googleapis.com/${CHROMEDRIVER_VERSION}/chromedriver_linux64.zip" && \
    unzip ${CHROMEDRIVER_DIR}/chromedriver* -d ${CHROMEDRIVER_DIR} && \
    rm ${CHROMEDRIVER_DIR}/chromedriver_linux64.zip

# Copy configuration files and scripts
ADD torrc /etc/tor/torrc
RUN mkdir -p /scripts
WORKDIR /scripts
COPY ./requirements.txt ./
RUN pip install --no-cache-dir -r requirements.txt
COPY ./entrypoint.sh /scripts/entrypoint.sh
COPY ./hit.py /scripts/hit.py
COPY ./refreship.py /scripts/refreship.py
RUN chmod +x /scripts/entrypoint.sh

# Set entrypoint and command
ENTRYPOINT ["sh", "/scripts/entrypoint.sh"]
CMD ["bash"]
