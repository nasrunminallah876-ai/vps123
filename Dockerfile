FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install Desktop environment and tools (REMOVED: systemd, snapd, init)
RUN apt update -y && apt install --no-install-recommends -y \
    xfce4 \
    xfce4-goodies \
    tigervnc-standalone-server \
    novnc \
    websockify \
    sudo \
    xterm \
    vim \
    net-tools \
    curl \
    wget \
    git \
    tzdata \
    dbus-x11 \
    x11-utils \
    x11-xserver-utils \
    x11-apps \
    software-properties-common \
    xubuntu-icon-theme && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 2. Install Firefox via PPA (Avoiding Snap entirely)
RUN add-apt-repository ppa:mozillateam/ppa -y && \
    echo 'Package: *' > /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin: release o=LP-PPA-mozillateam' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin-Priority: 1001' >> /etc/apt/preferences.d/mozilla-firefox && \
    apt update -y && apt install -y firefox

# 3. Setup VNC environment
RUN mkdir -p /root/.vnc && \
    touch /root/.Xauthority && \
    echo "#!/bin/bash\nstartxfce4 &" > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# 4. Generate SSL certificate for noVNC
RUN openssl req -new -subj "/C=JP" -x509 -days 365 -nodes -out /self.pem -keyout /self.pem

EXPOSE 5901
EXPOSE 6080

# 5. Start the services
# We use a proper bash script approach to ensure VNC starts BEFORE websockify
CMD bash -c "rm -rf /tmp/.X*-lock /tmp/.X11-unix && \
    vncserver :1 -localhost no -SecurityTypes None -geometry 1024x768 --I-KNOW-THIS-IS-INSECURE && \
    websockify --web=/usr/share/novnc/ --cert=/self.pem 6080 localhost:5901"
