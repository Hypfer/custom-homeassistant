# modify_frontend.py
import os
import gzip
import brotli
import pathlib
import sys

def log(message):
    print(f"{message}")

log("Starting frontend modifications...")
frontend_dir = sys.argv[1]
log(f"Frontend directory: {frontend_dir}")

replacements = [
    ("https://brands.home-assistant.io", "/local/brands"),
    (".zoom-hint{", ".zoom-hint{display:none !important;"),
    ("\"home\"!==t.state&&", ""),
]
log("Replacements to perform:")
for old, new in replacements:
    log(f" - '{old}' -> '{new}'")

def process_file(content):
    modified = False
    for old, new in replacements:
        if old in content:
            content = content.replace(old, new)
            modified = True
    return content, modified

# Process regular .js files
log("\nProcessing regular .js files...")
for js_file in pathlib.Path(frontend_dir).rglob("*.js"):
    if not any(ext in str(js_file) for ext in [".br", ".gz"]):
        #log(f"Processing: {js_file}")
        content = js_file.read_text()
        processed, modified = process_file(content)
        if modified:
            js_file.write_text(processed)
            log(f"Modified: {js_file}")

# Process .js.gz files
log("\nProcessing .js.gz files...")
for gz_file in pathlib.Path(frontend_dir).rglob("*.js.gz"):
    #log(f"Processing: {gz_file}")
    content = gzip.decompress(gz_file.read_bytes()).decode()
    processed, modified = process_file(content)
    if modified:
        with gzip.open(gz_file, "wb") as f:
            f.write(processed.encode())
        log(f"Modified: {gz_file}")

# Process .js.br files
log("\nProcessing .js.br files...")
for br_file in pathlib.Path(frontend_dir).rglob("*.js.br"):
    #log(f"Processing: {br_file}")
    content = brotli.decompress(br_file.read_bytes()).decode()
    processed, modified = process_file(content)
    if modified:
        br_file.write_bytes(brotli.compress(processed.encode()))
        log(f"Modified: {br_file}")

log("\nFrontend modification complete!")