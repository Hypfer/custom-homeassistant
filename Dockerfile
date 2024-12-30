FROM ghcr.io/home-assistant/home-assistant:2024.12.5

# Allow patching
RUN apk add gzip patch brotli

# Actual patching
COPY patches /patches

RUN for patch in /patches/hass/*.patch; do \
    patch -p1 -d /usr/src/homeassistant < "$patch"; \
done


RUN PYTHON_SITE_PACKAGES_DIR=$(python3 -c 'import site; print(site.getsitepackages()[0])') && \
    for patch in /patches/py/*.patch; do \
        patch -p1 -d "$PYTHON_SITE_PACKAGES_DIR" < "$patch"; \
    done

# Brands should be local => https://github.com/home-assistant/brands
# The local build should be placed in config/www/brands/
RUN PYTHON_SITE_PACKAGES_DIR=$(python3 -c 'import site; print(site.getsitepackages()[0])') && \
    cd "$PYTHON_SITE_PACKAGES_DIR/hass_frontend/" && \
    for i in $(find . -iname "*.js.gz"); do \
        zcat "$i" | sed 's/https:\/\/brands.home-assistant.io/\/local\/brands/g' > "$i.tmp" && \
        gzip -f "$i.tmp" && \
        mv "$i.tmp.gz" "$i"; \
    done && \
    for i in $(find . -iname "*.js.br"); do \
        brotli -dc "$i" | sed 's/https:\/\/brands.home-assistant.io/\/local\/brands/g' > "$i.tmp" && \
        brotli -f "$i.tmp" && \
        mv "$i.tmp.br" "$i"; \
    done && \
    for i in $(find . -iname "*.js"); do \
        sed -i 's/https:\/\/brands.home-assistant.io/\/local\/brands/g' "$i"; \
    done