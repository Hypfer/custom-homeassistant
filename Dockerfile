FROM ghcr.io/home-assistant/home-assistant:2026.3.0

# Allow patching
RUN apk add gzip patch brotli

# Actual patching
COPY patches /patches

RUN for patch in /patches/hass/*.patch; do \
    echo "Applying $patch"; \
    patch -p1 -d /usr/src/homeassistant < "$patch"; \
done

RUN PYTHON_SITE_PACKAGES_DIR=$(python3 -c 'import site; print(site.getsitepackages()[0])') && \
    for patch in /patches/py/*.patch; do \
        echo "Applying $patch"; \
        patch -p1 -d "$PYTHON_SITE_PACKAGES_DIR" < "$patch"; \
    done

COPY modify_frontend.py /
RUN PYTHON_SITE_PACKAGES_DIR=$(python3 -c 'import site; print(site.getsitepackages()[0])') && \
    python3 /modify_frontend.py "$PYTHON_SITE_PACKAGES_DIR/hass_frontend/"
