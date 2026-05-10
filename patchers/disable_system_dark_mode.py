import os, sys

frontend_dir = sys.argv[1]

replacements = [
    ("@media (prefers-color-scheme: dark)", "@media not all"),
    ("@media (prefers-color-scheme:dark)", "@media not all"),
]

total = 0
for root, dirs, files in os.walk(frontend_dir):
    for fname in files:
        fpath = os.path.join(root, fname)
        try:
            content = open(fpath, "r", encoding="utf-8").read()
        except (UnicodeDecodeError, PermissionError):
            continue
        original = content
        for old, new in replacements:
            count = content.count(old)
            if count:
                content = content.replace(old, new)
                rel = os.path.relpath(fpath, frontend_dir)
                print(f"  {rel}: {old!r} -> {new!r} ({count}x)")
                total += count
        if content != original:
            open(fpath, "w", encoding="utf-8").write(content)

print(f"Total replacements: {total}")
