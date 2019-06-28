#
# Provides a deploy image for Trellis with:
# - Ubuntu 18.04
# - Ansible
# - Node.js 11
# - Yarn
#
FROM ubuntu:18.04

LABEL author="Samuel Marchal <samuel@148.fr>"

# Adding Ansible's prerequisites
RUN apt-get update -y \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y -q \
        build-essential \
        python python-pip python-dev \
        libffi-dev libssl-dev \
        libxml2-dev libxslt1-dev zlib1g-dev \
        git

# Adding Node.js and Yarn prerequisites
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y curl \
    && curl -sL https://deb.nodesource.com/setup_11.x | bash \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

# Upgrading pip
# @see https://github.com/pypa/pip/issues/5240#issuecomment-383129401
RUN python -m pip install --upgrade pip \
    && pip install --upgrade setuptools wheel \
    && pip install --upgrade pyyaml jinja2 pycrypto \
    && pip install --upgrade pywinrm

# Downloading Ansible's source tree
RUN git clone git://github.com/ansible/ansible.git --recursive

# Compiling Ansible
RUN cd ansible \
    && bash -c 'source ./hacking/env-setup'

# Moving useful Ansible stuff to /opt/ansible
RUN mkdir -p /opt/ansible \
    && mv /ansible/bin  /opt/ansible/bin \
    && mv /ansible/lib  /opt/ansible/lib \
    && mv /ansible/docs /opt/ansible/docs \
    && rm -rf /ansible

# Installing Node.js and Yarn
RUN apt-get install -y nodejs yarn

# Installing handy tools (not absolutely required)
RUN apt-get install -y sshpass openssh-client

# Clean up
RUN apt-get remove -y --auto-remove \
        build-essential \
        python-pip \
        python-dev \
        git \
        libffi-dev \
        libssl-dev \
        curl \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Adding hosts for convenience
RUN mkdir -p /etc/ansible \
    && echo 'localhost' > /etc/ansible/hosts

# Define environment variables
ENV PATH        /opt/ansible/bin:$PATH
ENV PATH        /opt/yarn-1.16.0/bin:$PATH
ENV PYTHONPATH  /opt/ansible/lib:$PYTHONPATH
ENV MANPATH     /opt/ansible/docs/man:$MANPATH

# Default command: displays Ansible version
CMD [ "ansible-playbook", "--version" ]
