FROM debian:buster-slim

# culr (optional) for downloading/browsing stuff
# openssh-client (required) for creating ssh tunnel
# psmisc (optional) I needed it to test port binding after ssh tunnel (eg: netstat -ntlp | grep 6443)
# nano (required) buster-slim doesn't even have less. so I needed an editor to view/edit file (eg: /etc/hosts) 
# jq for parsing json (output of az commands, kubectl output etc)

RUN apt-get update && apt-get install -y \
	apt-transport-https \
	ca-certificates \
	curl \
    openssh-client \
	psmisc \
	nano \
	less \
	net-tools \
	&& curl -L https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
	&& chmod +x /usr/local/bin/kubectl

RUN curl -o /usr/local/bin/jq -L https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 && \
  	chmod +x /usr/local/bin/jq
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
RUN curl -sSL https://get.docker.com/ | sh

# COPY .ssh/id_rsa /root/.ssh/
# COPY .ssh/known_hosts /root/.ssh/
# RUN chmod 600 /root/.ssh/id_rsa

COPY binaries/tanzu-cli-bundle-linux-amd64.tar /tmp/
RUN cd /tmp && mkdir tanzu \
	&& tar -xvf tanzu-cli-bundle-linux-amd64.tar -C tanzu/ \
	&& cd /tmp/tanzu/cli \
	&& install core/v1.3.1/tanzu-core-linux_amd64 /usr/local/bin/tanzu \
	&& cd /tmp/tanzu \
	&& tanzu plugin clean \
	&& tanzu plugin install --local cli all \
	&& tanzu plugin list \
	&& tanzu plugin install management-cluster \
	&& tanzu plugin install cluster \
	&& tanzu plugin install login \
	&& tanzu plugin install kubernetes-release \
	&& tanzu plugin install alpha \
	&& tanzu plugin install pinniped-auth



COPY binaries/tkginstall.sh /usr/local/tkginstall.sh
RUN chmod +x /usr/local/tkginstall.sh


ENTRYPOINT [ "/usr/local/tkginstall.sh"]