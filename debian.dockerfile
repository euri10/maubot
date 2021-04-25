FROM node:12 AS frontend-builder

COPY ./maubot/management/frontend /frontend
RUN cd /frontend && yarn --prod && yarn build

FROM debian:bullseye-slim

RUN export DEBIAN_FRONTEND=noninteractive && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y --no-install-recommends \
    build-essential \
    git \
    libolm-dev \
    python3-pip \
    python3-dev \
    libmagic-dev \
    ca-certificates && \
  apt-get -y clean && \
  rm -rf /var/lib/apt/lists/*

COPY requirements.txt /opt/maubot/requirements.txt
COPY optional-requirements.txt /opt/maubot/optional-requirements.txt
WORKDIR /opt/maubot
RUN pip install -r requirements.txt -r optional-requirements.txt \
        dateparser langdetect python-gitlab pyquery cchardet
# TODO also remove dateparser, langdetect and pyquery when maubot supports installing dependencies

# aipic
RUN pip install pillow scikit-image torchvision python-magic \
# rss
    feedparser

COPY . /opt/maubot
COPY ./docker/mbc.sh /usr/local/bin/mbc
COPY --from=frontend-builder /frontend/build /opt/maubot/frontend
ENV UID=1337 GID=1337 XDG_CONFIG_HOME=/data
VOLUME /data

CMD ["/opt/maubot/docker/run.sh"]
