FROM fedora:latest
RUN mkdir /koji
WORKDIR /koji

RUN dnf install -y koji bash python-jinja2 python-requests skopeo docker xz && dnf clean all
CMD "/bin/bash"
ENV DISTTAG=f32container FGC=f32 FBR=f32

