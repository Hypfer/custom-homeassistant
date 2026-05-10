ARG HA_IMAGE=ghcr.io/home-assistant/home-assistant:2026.5.0

FROM ${HA_IMAGE} AS extract

RUN pip show home-assistant-frontend | grep ^Version: | cut -d' ' -f2 | tr -d '\r\n' > /frontend_version && \
    PYTHON_SITE_PACKAGES_DIR=$(python3 -c 'import site; print(site.getsitepackages()[0])') && \
    cp -r "$PYTHON_SITE_PACKAGES_DIR/hass_frontend/static/translations" /translations_built



FROM node:24-alpine AS build

RUN sed -i 's|https://dl-cdn.alpinelinux.org/alpine|https://mirrors.edge.kernel.org/alpine|g' /etc/apk/repositories && \
    apk add --no-cache git patch python3

COPY --from=extract /frontend_version /frontend_version
COPY --from=extract /translations_built /translations_built

RUN FRONTEND_VERSION=$(cat /frontend_version) && \
    git clone --depth 1 --branch "$FRONTEND_VERSION" https://github.com/home-assistant/frontend.git /frontend

COPY patches/frontend /patches_frontend

RUN cd /frontend && \
    set -euo pipefail && \
    for patch in /patches_frontend/*.patch; do \
        echo "Applying $patch"; \
        patch -p1 --no-backup-if-mismatch < "$patch"; \
    done

COPY patchers/disable_system_dark_mode.py /disable_system_dark_mode.py
RUN python3 /disable_system_dark_mode.py /frontend

COPY patchers/custom_version_suffix.py /custom_version_suffix.py
RUN python3 /custom_version_suffix.py /frontend

COPY patchers/force_reduced_motion.py /force_reduced_motion.py
RUN python3 /force_reduced_motion.py /frontend

RUN BUILD_TS=$(date +%s) && \
    sed -i "s/version      = \"\([^\"]*\)\"/version      = \"\1+custom.${BUILD_TS}\"/" /frontend/pyproject.toml && \
    echo "Frontend version: $(grep '^version' /frontend/pyproject.toml)"

COPY utils/unflatten_translations.py /unflatten_translations.py
RUN python3 /unflatten_translations.py

RUN cd /frontend && \
    yarn install && \
    ./node_modules/.bin/gulp build-app && \
    echo "// Build: $(date +%s)" >> hass_frontend/sw-modern.js && \
    echo "// Build: $(date +%s)" >> hass_frontend/sw-legacy.js



FROM ${HA_IMAGE}

RUN sed -i 's|https://dl-cdn.alpinelinux.org/alpine|https://mirrors.edge.kernel.org/alpine|g' /etc/apk/repositories && \
    apk add --no-cache patch

COPY patches /patches

RUN set -euo pipefail && \
    for patch in /patches/hass/*.patch; do \
        echo "Applying $patch"; \
        patch -p1 -d /usr/src/homeassistant --no-backup-if-mismatch < "$patch"; \
    done

RUN set -euo pipefail && \
    PYTHON_SITE_PACKAGES_DIR=$(python3 -c 'import site; print(site.getsitepackages()[0])') && \
    for patch in /patches/py/*.patch; do \
        echo "Applying $patch"; \
        patch -p1 -d "$PYTHON_SITE_PACKAGES_DIR" --no-backup-if-mismatch < "$patch"; \
    done

COPY --from=build /frontend/hass_frontend /hass_frontend_built

RUN PYTHON_SITE_PACKAGES_DIR=$(python3 -c 'import site; print(site.getsitepackages()[0])') && \
    rm -rf "$PYTHON_SITE_PACKAGES_DIR/hass_frontend" && \
    cp -r /hass_frontend_built "$PYTHON_SITE_PACKAGES_DIR/hass_frontend"
