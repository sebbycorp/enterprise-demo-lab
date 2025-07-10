FROM alpine:latest

RUN apk update && \
    apk add libteam open-lldp sudo tcpdump scapy iperf3 && \
    apk add docker docker-compose

RUN adduser -u 1000 -G wheel -D alpine && \
    addgroup alpine docker && \
    echo "%wheel ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

COPY entrypoint.sh /home/alpine/
RUN chmod +x /home/alpine/entrypoint.sh

USER alpine

ENTRYPOINT ["/home/alpine/entrypoint.sh"]
CMD []