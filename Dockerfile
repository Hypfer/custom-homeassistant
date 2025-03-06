FROM ghcr.io/home-assistant/home-assistant:2025.3.0

# Allow patching
RUN apk add gzip patch brotli

# Actual patching
COPY patches /patches

RUN for patch in /patches/hass/*.patch; do \
    patch -p1 -d /usr/src/homeassistant < "$patch"; \
done

RUN for i in $(find /usr/src/homeassistant -type f -name "*.py"); do \
    sed -i 's;https://brands.home-assistant.io;/local/brands;g' "$i"; \
done


RUN PYTHON_SITE_PACKAGES_DIR=$(python3 -c 'import site; print(site.getsitepackages()[0])') && \
    for patch in /patches/py/*.patch; do \
        patch -p1 -d "$PYTHON_SITE_PACKAGES_DIR" < "$patch"; \
    done

# Brands should be local => https://github.com/home-assistant/brands
# The local build should be placed in config/www/brands/

COPY modify_frontend.py /
RUN PYTHON_SITE_PACKAGES_DIR=$(python3 -c 'import site; print(site.getsitepackages()[0])') && \
    python3 /modify_frontend.py "$PYTHON_SITE_PACKAGES_DIR/hass_frontend/"


COPY modify_custom_components.py /
COPY custom_entrypoint.sh /custom_entrypoint.sh
RUN chmod +x /custom_entrypoint.sh
ENTRYPOINT ["/custom_entrypoint.sh"]