FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Stage 1: Basic Tools and XFCE Core
RUN apt-get update && apt-get install -y --no-install-recommends \
    sudo xterm vim net-tools curl wget git tzdata dbus-x11 && \
    apt-get clean

# Stage 2: Desktop Environment (The heavy part)
RUN apt-get update && apt-get install -y --no-install-recommends \
    xfce4 xfce4-goodies xubuntu-icon-theme && \
    apt-get clean

# Stage 3: VNC and Web Access
RUN apt-get update && apt-get install -y --no-install-recommends \
    tigervnc-standalone-server novnc websockify openssl && \
    apt-get clean

# Stage 4: Firefox via PPA (Avoiding Snap)
RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository ppa:mozillateam/ppa -y && \
    echo 'Package: *' > /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin: release o=LP-PPA-mozillateam' >> /etc/apt/preferences.d/mozilla-firefox && \
    echo 'Pin-Priority: 1001' >> /etc/apt/preferences.d/mozilla-firefox && \
    apt-get update && apt-get install -y firefox && \
    rm -rf /var/lib/apt/lists/*

# Setup VNC
RUN mkdir -p /root/.vnc && \
    touch /root/.Xauthority && \
    echo "#!/bin/bash\nstartxfce4 &" > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

RUN openssl req -new -subj "/C=JP" -x509 -days 365 -nodes -out /self.pem -keyout /self.pem

EXPOSE 5901
EXPOSE 6080

CMD bash -c "rm -rf /tmp/.X*-lock /tmp/.X11-unix && \
    vncserver :1 -localhost no -SecurityTypes None -geometry 1024x768 --I-KNOW-THIS-IS-INSECURE && \
    websockify --web=/usr/share/novnc/ --cert=/self.pem 6080 localhost:5901"
