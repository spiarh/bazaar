FROM jenkins/jenkins:alpine

# Manage plugins
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

# Add Jenkins Configuration As Code file
COPY jenkins.yaml /jenkins.yaml
