import json, os, re, glob, datetime

built_dir = "/translations_built"
out_dir = "/frontend/translations/frontend"
os.makedirs(out_dir, exist_ok=True)


def unflatten_key(key, val, target):
    parts = key.split(".")
    d = target
    for p in parts[:-1]:
        d = d.setdefault(p, {})
    d[parts[-1]] = val


total_keys = 0
total_subdir_files = 0
locales_done = 0

for fp in glob.glob(os.path.join(built_dir, "*.json")):
    fn = os.path.basename(fp)
    m = re.match(r"^([a-z]{2}(?:-[A-Za-z0-9]+)?)-[a-f0-9]+\.json$", fn)
    if not m:
        continue
    locale = m.group(1)
    with open(fp, encoding="utf-8") as f:
        flat = json.load(f)
    nested = {}
    for key, val in flat.items():
        unflatten_key(key, val, nested)
    subdir_keys = 0
    # Process subdirectory (panel fragment) files for this locale
    for subdir_fp in glob.glob(os.path.join(built_dir, "*", "*.json")):
        subdir_fn = os.path.basename(subdir_fp)
        subdir_m = re.match(r"^([a-z]{2}(?:-[A-Za-z0-9]+)?)-[a-f0-9]+\.json$", subdir_fn)
        if not subdir_m or subdir_m.group(1) != locale:
            continue
        with open(subdir_fp, encoding="utf-8") as f:
            subdir_flat = json.load(f)
        for key, val in subdir_flat.items():
            unflatten_key(key, val, nested)
        subdir_keys += len(subdir_flat)
        total_subdir_files += 1
    with open(os.path.join(out_dir, f"{locale}.json"), "w", encoding="utf-8") as f:
        json.dump(nested, f, ensure_ascii=False)
    all_keys = len(flat) + subdir_keys
    total_keys += all_keys
    locales_done += 1
    print(f"  {locale}.json: {len(flat)} base + {subdir_keys} panel = {all_keys} total")

artifact_dir = "/frontend/translations"
os.makedirs(artifact_dir, exist_ok=True)
with open(os.path.join(artifact_dir, "artifact.json"), "w") as f:
    json.dump({"created_at": datetime.datetime.now().isoformat()}, f)
print(f"Done: {locales_done} locales, {total_subdir_files} panel files, {total_keys} total keys")
