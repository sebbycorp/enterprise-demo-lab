FROM alpine:latest

# Install required packages and kernel modules
RUN apk update && \
    apk add libteam open-lldp sudo tcpdump scapy iperf3 \
            docker docker-compose iproute2 ethtool && \
    rm -rf /var/cache/apk/*

# Create user and setup sudo
RUN adduser -u 1000 -G wheel -D alpine && \
    addgroup alpine docker && \
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Copy and setup entrypoint
COPY entrypoint.sh /home/alpine/
RUN chmod +x /home/alpine/entrypoint.sh

USER alpine
WORKDIR /home/alpine

ENTRYPOINT ["/home/alpine/entrypoint.sh"]