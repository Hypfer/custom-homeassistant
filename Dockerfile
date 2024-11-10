FROM ghcr.io/home-assistant/home-assistant:2024.11.1

# Allow patching
RUN apk add gzip patch

# For shutting down windows computers via the network
RUN apk add samba-client samba-common-tools

# Actual patching
COPY patches /patches

RUN for patch in /patches/hass/*.patch; do \
    patch -p1 -d /usr/src/homeassistant < "$patch"; \
done

# Dynamically discovers the current python version
RUN PYTHON_SITE_PACKAGES_DIR=$(python3 -c 'import site; print(site.getsitepackages()[0])') && \
    for patch in /patches/py/*.patch; do \
        patch -p1 -d "$PYTHON_SITE_PACKAGES_DIR" < "$patch"; \
    done