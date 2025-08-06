# Zip command (run in the root directory of folder): zip -r ../fullstack-base-image.zip . -x "*.DS_Store" "*__MACOSX*" "._*"
FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV NGINX_FILES_PATH=/home/nginx

# Common sdk or packages required to install languages
RUN apt-get update && apt-get install --no-install-recommends -y \
    git \
    gpg \
    curl \
    wget \
    lsb-release \
    add-apt-key \
    ca-certificates \
    dumb-init \
    git \
    sudo \
    build-essential \
    ucommon-utils \
    zip \
    unzip \
    openssh-server \
    libarchive-tools \
    locales \
    nginx \
    supervisor \
    libgtk2.0-0 \
    libgtk-3-0 \
    libgbm-dev \
    libnotify-dev \
    libnss3 \
    libxss1 \
    libasound2 \
    libxtst6 \
    xauth \
    xvfb && apt-get clean

# Install MongoDB
RUN apt-get install gnupg curl \
    && curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | \
    sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg \
    --dearmor \
    && echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-8.0.list \
    && apt-get update \
    && apt-get install -y mongodb-org

# Node SDK
RUN curl -sL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install --no-install-recommends -y nodejs \
    && npm install -g typescript

# Code-Server
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8
ENV DISABLE_TELEMETRY true

ENV CODE_VERSION="3.12.0"
RUN curl -fsSL https://code-server.dev/install.sh | bash /dev/stdin --version $CODE_VERSION

RUN groupadd -r coder \
    && useradd -m -r coder -g coder -s /bin/bash \
    && echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd
USER coder

ENV VSCODE_USER "/home/coder/.local/share/code-server/User"
ENV VSCODE_EXTENSIONS "/home/coder/.local/share/code-server/extensions"
RUN mkdir -p ${VSCODE_USER}

ENV SERVICE_URL=https://open-vsx.org/vscode/gallery 
ENV ITEM_URL=https://open-vsx.org/vscode/item

RUN code-server --install-extension formulahendry.code-runner --extensions-dir=$VSCODE_EXTENSIONS \
    && code-server --install-extension ecmel.vscode-html-css --extensions-dir=$VSCODE_EXTENSIONS \
    && code-server --install-extension xabikos.JavaScriptSnippets --extensions-dir=$VSCODE_EXTENSIONS \
    && code-server --install-extension ms-vscode.node-debug2 --extensions-dir=$VSCODE_EXTENSIONS \
    && code-server --install-extension esbenp.prettier-vscode \
    && code-server --install-extension msjsdiag.debugger-for-chrome --extensions-dir=$VSCODE_EXTENSIONS \
    && code-server --install-extension ritwickdey.liveServer --extensions-dir=$VSCODE_EXTENSIONS \
    && code-server --install-extension dsznajder.es7-react-js-snippets --extensions-dir=$VSCODE_EXTENSIONS \
    && code-server --install-extension dbaeumer.vscode-eslint --extensions-dir=$VSCODE_EXTENSIONS

COPY extensions/auchenberg.vscode-browser-preview-0.6.7.vsix /tmp/
RUN mkdir -p $VSCODE_EXTENSIONS/vscode-browser-preview \
    && bsdtar --strip-components=1 -xf /tmp/auchenberg.vscode-browser-preview-0.6.7.vsix -C $VSCODE_EXTENSIONS/vscode-browser-preview extension

COPY extensions/coursera-launch-button-0.0.1.vsix /tmp/
RUN mkdir -p $VSCODE_EXTENSIONS/coursera-launch-button \
    && bsdtar --strip-components=1 -xf /tmp/coursera-launch-button-0.0.1.vsix -C $VSCODE_EXTENSIONS/coursera-launch-button extension

COPY index.html /home/travis/build/codercom/code-server/packages/server/build/web/

RUN find $VSCODE_EXTENSIONS -wholename "*ritwickdey.liveserver*/out/src/announcement/index.js" \
    | xargs sed -i --expression='/showInformationMessage/d'

ENV SHELL /bin/bash

USER root

COPY --chown=coder:coder coursera-launch-button/ $VSCODE_USER/coursera/
COPY --chown=coder:coder launchButtonSettings.json /tmp/launchButtonSettings.json
RUN mkdir -p /home/coder/coursera
COPY --chown=coder:coder settings.json $VSCODE_USER
COPY start.sh /usr/local/bin/
COPY config.yaml /tmp/config/code-server/
RUN chmod 755 /usr/local/bin/start.sh

COPY coursera-submission /tmp/coursera
RUN for d in $(ls /usr/lib | grep "^python*") ; do cp -r /tmp/coursera /usr/lib/$d; done

VOLUME ["/etc/nginx/sites-enabled", "/etc/nginx/certs", "/etc/nginx/conf.d", "/var/log/nginx", "/var/www/html"]
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

RUN mkdir -p $NGINX_FILES_PATH
COPY nginx-files/ /tmp/nginx-files/

USER coder

RUN mkdir -p /var/log/supervisor
RUN sudo touch /var/log/supervisor/supervisord.log \
  && sudo touch /var/log/supervisor/code-server-stdout.log \
  && sudo touch /var/log/supervisor/code-server-stderr.log
RUN sudo chmod 766 /var/log/supervisor/*

RUN mkdir -p /home/coder/project
COPY .hidden /tmp/.hidden
COPY nginx-files/reverse-proxy.conf /etc/nginx/sites-enabled/reverse-proxy.conf.template

RUN sudo mkdir -p /home/npm-global
WORKDIR /home/npm-global
RUN sudo npm init -y
RUN sudo npm config set prefix /home/npm-global --global
RUN sudo chown coder:coder /home/npm-global

USER coder

RUN npm install --global nginx-conf 

USER root

WORKDIR /home/coder/project
ENTRYPOINT ["dumb-init", "--"]
CMD ["start.sh"]