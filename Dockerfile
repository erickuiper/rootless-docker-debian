FROM debian:stable-slim AS base

RUN set -eux; \
    apt-get update; \
    apt-get upgrade -y; \
    apt-get install -y -qq --no-install-recommends \
    apt-transport-https apt-utils curl lsb-release gnupg   

RUN et -eux; \
    mkdir -p /etc/apt/keyrings; \
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg; \
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null; \
    DEBIAN_FRONTEND=noninteractive apt-get update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --no-install-recommends \
    docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-ce-rootless-extras \
    slirp4netns uidmap iproute2

RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# create a default user preconfigured for running rootless dockerd
RUN set -eux; \
    groupadd -g 1000 rootless; \
    useradd -l -m -u 1000 -g 1000 -s /bin/bash rootless; \
	echo 'rootless:100000:65536' >> /etc/subuid; \
	echo 'rootless:100000:65536' >> /etc/subgid; \
    mkdir -p /home/rootless/.docker/run && \
    mkdir -p /home/rootless/.local/share/docker && \
    chown -R rootless:rootless  /home/rootless; \
    chmod -R 777 /home/rootless; 

ENV XDG_RUNTIME_DIR=/home/rootless/.docker/run
ENV PATH=/usr/bin:$PATH
ENV DOCKER_HOST=unix:///home/rootless/.docker/run/docker.sock   

USER rootless
CMD /bin/bash

ENTRYPOINT [ "nohup /usr/bin/dockerd-rootless.sh --iptables=false &" ]
