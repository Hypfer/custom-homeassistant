import os, sys

frontend_dir = sys.argv[1]
env_cjs = os.path.join(frontend_dir, "build-scripts", "env.cjs")

content = open(env_cjs, "r", encoding="utf-8").read()
old = r'(?:\.dev)?)"'
new = r'(?:\.dev)?(?:[+].+)?)"'

if old in content:
    content = content.replace(old, new)
    open(env_cjs, "w", encoding="utf-8").write(content)
    print(f"  build-scripts/env.cjs: allowed +suffix in version regex")
else:
    print("  WARNING: version regex not found in env.cjs")
