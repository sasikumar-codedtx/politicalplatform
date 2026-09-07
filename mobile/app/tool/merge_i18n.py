"""Merge per-screen i18n fragments (i18n_parts/*.json) into assets/i18n/en.json
and ta.json. Each fragment is { "key": {"en": "...", "ta": "..."} }."""
import json, glob, os

root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
parts = sorted(glob.glob(os.path.join(root, "i18n_parts", "*.json")))
en, ta, collisions = {}, {}, []

for p in parts:
    try:
        data = json.load(open(p, encoding="utf-8"))
    except Exception as e:
        print(f"SKIP {os.path.basename(p)}: {e}")
        continue
    for key, v in data.items():
        if key in en:
            collisions.append(key)
        en[key] = (v.get("en") if isinstance(v, dict) else str(v)) or ""
        ta[key] = (v.get("ta") if isinstance(v, dict) else "") or en[key]

out = os.path.join(root, "assets", "i18n")
os.makedirs(out, exist_ok=True)
json.dump(en, open(os.path.join(out, "en.json"), "w", encoding="utf-8"),
          ensure_ascii=False, indent=2, sort_keys=True)
json.dump(ta, open(os.path.join(out, "ta.json"), "w", encoding="utf-8"),
          ensure_ascii=False, indent=2, sort_keys=True)
print(f"merged {len(parts)} fragments -> {len(en)} keys; {len(collisions)} collisions")
if collisions:
    print("collisions:", collisions[:20])
