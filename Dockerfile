FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install Core Tools and GPG (Fixed the PPA gpg-agent error)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gnupg2 \
    dirmngr \
    ca-certificates \
    software-properties-common \
    curl \
    wget \
    git \
    sudo \
    vim \
    net-tools \
    tzdata && \
    apt-get clean

# 2. Install Firefox via PPA (Avoiding Snap)
RUN add-apt-repository ppa:mozillateam/ppa -y && \
    echo 'Package: *' > /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin: release o=LP-PPA-mozillateam' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin-Priority: 1001' >> /etc/apt/preferences.d/mozilla-firefox && \
    apt-get update && apt-get install -y firefox

# 3. Install Desktop Environment (XFCE4)
# Removed: systemd, snapd, and init to prevent VPS kernel watchdog errors
RUN apt-get update && apt-get install -y --no-install-recommends \
    xfce4 \
    xfce4-goodies \
    xubuntu-icon-theme \
    dbus-x11 \
    x11-utils \
    x11-xserver-utils \
    x11-apps \
    xterm && \
    apt-get clean

# 4. Install VNC and noVNC (Web interface)
RUN apt-get update && apt-get install -y --no-install-recommends \
    tigervnc-standalone-server \
    novnc \
    websockify && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# 5. Environment Setup
RUN mkdir -p /root/.vnc && \
    touch /root/.Xauthority && \
    echo "#!/bin/bash\nstartxfce4 &" > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# Generate SSL certificate for secure noVNC access
RUN openssl req -new -subj "/C=PK" -x509 -days 365 -nodes -out /self.pem -keyout /self.pem

EXPOSE 5901
EXPOSE 6080

# 6. Startup Command
# Cleans up old locks before starting to prevent "Display already in use" errors
CMD bash -c "rm -rf /tmp/.X*-lock /tmp/.X11-unix && \
    vncserver :1 -localhost no -SecurityTypes None -geometry 1024x768 --I-KNOW-THIS-IS-INSECURE && \
    websockify --web=/usr/share/novnc/ --cert=/self.pem 6080 localhost:5901"
