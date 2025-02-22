#!/bin/bash

# Path for custom components
CUSTOM_COMPONENTS_PATH=/config/custom_components

# Check if the custom components directory exists
if [ -d "$CUSTOM_COMPONENTS_PATH" ]; then
    echo "Running modifications on custom components..."
    python3 /modify_custom_components.py "$CUSTOM_COMPONENTS_PATH"
else
    echo "Custom components directory not found at $CUSTOM_COMPONENTS_PATH"
fi

# Execute the main Home Assistant command
exec /init
