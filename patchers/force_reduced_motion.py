import os, sys

frontend_dir = sys.argv[1]

replacements = [
    ("@media not (prefers-reduced-motion)", "@media not all"),
    ("@media (prefers-reduced-motion: reduce)", "@media all"),
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

loader = os.path.join(frontend_dir, "src", "html", "_js_base.html.template")
monkeypatch = """<script>
// Force prefers-reduced-motion for all JS matchMedia calls
(function() {
  var c=window.console;c.log&&c.log('[ha-patch] overriding matchMedia to force prefers-reduced-motion');
  var _mm = window.matchMedia.bind(window);
  window.matchMedia = function(q) {
    var m = _mm(q);
    if (q.indexOf("prefers-reduced-motion") !== -1) Object.defineProperty(m, "matches", { value: true });
    return m;
  };
})();
</script>
"""
content = open(loader, "r", encoding="utf-8").read()
open(loader, "w", encoding="utf-8").write(monkeypatch + content)
print(f"  src/html/_js_base.html.template: injected matchMedia monkeypatch")
total += 1

print(f"Total replacements: {total}")
