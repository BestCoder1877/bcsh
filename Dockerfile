FROM alpine:latest

RUN apk add bash sudo curl shadow util-linux-login

WORKDIR /app
COPY . .

RUN export BCSH_DEV_MODE=1 && ./install.sh

RUN useradd -m -s /bin/bcsh code
RUN passwd -d code
RUN echo "code ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/code

WORKDIR /home/code
