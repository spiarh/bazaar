FROM jenkins-slave/default:stable

ENV pyvomi_version=6.7.0.2018.9

# Install vmware requirements
RUN pip3 install --no-cache-dir pyvmomi==${pyvomi_version}
