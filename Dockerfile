FROM python:3.9.17-slim-bullseye AS builder

ARG BUILD_DEPS="\
    docker \
    gcc \
    libc-dev \
    libffi-dev \
    make \
    musl-dev \
    openssh-client \
    "

RUN apt-get update && \
    apt-get install --no-install-recommends -y ${BUILD_DEPS} && \
    rm -rf /var/lib/apt/lists/*

COPY Pipfile* ./
RUN pip install --no-cache-dir pipenv && \
    pipenv install --deploy --system

FROM python:3.9.17-slim-bullseye AS runtime

LABEL "maintainer"="https://github.com/RedlineTriad/"
LABEL "repository"="https://github.com/RedlineTriad/molecule-vagrant-qemu-action"
LABEL "com.github.actions.name"="molecule"
LABEL "com.github.actions.description"="Run Ansible Molecule"
LABEL "com.github.actions.icon"="upload"
LABEL "com.github.actions.color"="green"

COPY --from=builder /usr/local/lib/python3.9/site-packages/ /usr/local/lib/python3.9/site-packages/
COPY --from=builder /usr/local/bin/ansible*  /usr/local/bin/
COPY --from=builder /usr/local/bin/flake8    /usr/local/bin/flake8
COPY --from=builder /usr/local/bin/molecule  /usr/local/bin/molecule
COPY --from=builder /usr/local/bin/pytest    /usr/local/bin/pytest
COPY --from=builder /usr/local/bin/yamllint  /usr/local/bin/yamllint

ARG PACKAGES="\
    git \
    libvirt-daemon-driver-qemu \
    openssh-client \
    qemu \
    qemu-utils \
    qemu-system \
    tini \
    vagrant \
    "

RUN apt-get update && \
    apt-get install --no-install-recommends -y ${PACKAGES} && \
    rm -rf /var/lib/apt/lists/*

RUN vagrant plugin install vagrant-qemu

ENTRYPOINT ["/usr/bin/tini", "--"]
CMD cd ${INPUT_MOLECULE_WORKING_DIR}; molecule ${INPUT_MOLECULE_OPTIONS} ${INPUT_MOLECULE_COMMAND} ${INPUT_MOLECULE_ARGS}
