ARG BASE_IMAGE=docker.io/bitnamilegacy/moodle@sha256:df3492f185922381361e8194bffb6d2425accd575992427d571ef12b5c30514c
ARG O365_MOODLE_REF=v20251223_m500
ARG O365_MOODLE_ARCHIVE_ROOT=20251223_m500

FROM ${BASE_IMAGE}

USER root

RUN install_packages curl tar \
 && curl -fsSL "https://codeload.github.com/microsoft/o365-moodle/tar.gz/refs/tags/${O365_MOODLE_REF}" -o /tmp/o365-moodle.tar.gz \
 && tar -xzf /tmp/o365-moodle.tar.gz -C /tmp \
 && mkdir -p /opt/bitnami/moodle/auth \
 && cp -a "/tmp/o365-moodle-${O365_MOODLE_ARCHIVE_ROOT}/auth/oidc" /opt/bitnami/moodle/auth/ \
 && test -d /opt/bitnami/moodle/auth/oidc \
 && chown -R 1001:0 /opt/bitnami/moodle/auth/oidc \
 && rm -rf /tmp/o365-moodle.tar.gz "/tmp/o365-moodle-${O365_MOODLE_ARCHIVE_ROOT}"

USER 1001
