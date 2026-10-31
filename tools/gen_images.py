"""Illusztrációk generálása az OpenAI képes API-jával egy PROMPTOK_*.md fájlból.

Használat (a projekt gyökeréből):
    python tools/gen_images.py assets/art/PROMPTOK_NEFRU.md [--only cards/c_nefru,...] [--force] [--dry]

Az API-kulcsot az OPENAI_API_KEY környezeti változóból vagy a %USERPROFILE%\\.openai_api_key
fájlból olvassa (a kulcs SOHA ne kerüljön a repóba). A kész képek az assets/art/<mappa>/<név>.png
helyre kerülnek; a már meglévőket kihagyja (--force: újragenerálja).

Visszatérő szereplőknél és a kártyakeretnél a már elkészült képeket referenciaként küldi
(images/edits végpont), hogy az arcok és a keret egységesek maradjanak.
"""
import base64, json, os, re, sys, time, uuid, urllib.request, urllib.error

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ART = os.path.join(ROOT, "assets", "art")
MODEL = os.environ.get("OPENAI_IMAGE_MODEL", "chatgpt-image-latest")
SIZES = {"souls": "1536x1024", "backgrounds": "1536x1024", "rooms": "1536x1024", "scenes": "1024x1536"}

# kulcsszó a promptban → referenciakép (az art mappához viszonyítva)
CHAR_REFS = [
    ("Nefru", "souls/nefru.png"),
    ("Tia,", "cards/c_tia.png"),
    ("Tia,", "scenes/nefru_childhood.png"),
    ("Hesi-Ra", "scenes/nefru_death.png"),
    ("Satre", "cards/c_satre.png"),
    ("Henut", "cards/c_henut.png"),
    ("Nebetta", "cards/c_nebetta.png"),
    ("Ptahmose,", "cards/c_ptahmose.png"),
]
FRAME_REF = "cards/c_nefru.png"
REF_NOTE = ("Use the attached reference image(s) only to keep recurring characters' faces, clothing and the "
            "decorative card frame consistent; compose a completely new image exactly as described below. ")


def api_key() -> str:
    k = os.environ.get("OPENAI_API_KEY", "").strip()
    if not k:
        p = os.path.join(os.path.expanduser("~"), ".openai_api_key")
        if os.path.exists(p):
            k = open(p, encoding="utf-8").read().strip()
    if not k:
        sys.exit("Nincs API-kulcs: állítsd be az OPENAI_API_KEY változót vagy a ~/.openai_api_key fájlt.")
    return k


def parse(md_path: str):
    text = open(md_path, encoding="utf-8").read()
    return re.findall(r"### `([^`]+)\.png`\s*```\s*(.*?)\s*```", text, re.S)


def refs_for(key: str, prompt: str):
    out = []
    folder = key.split("/")[0]
    for word, ref in CHAR_REFS:
        if "No people" in prompt:
            break
        if word in prompt and ref != key + ".png" and os.path.exists(os.path.join(ART, ref)):
            out.append(ref)
    if folder in ("cards", "spirits") and key + ".png" != FRAME_REF and os.path.exists(os.path.join(ART, FRAME_REF)):
        out.append(FRAME_REF)
    seen, uniq = set(), []
    for r in out:
        if r not in seen:
            seen.add(r)
            uniq.append(r)
    return uniq[:4]


def post_json(url, key, payload):
    req = urllib.request.Request(url, data=json.dumps(payload).encode(), method="POST",
                                 headers={"Authorization": "Bearer " + key, "Content-Type": "application/json"})
    return urllib.request.urlopen(req, timeout=300)


def post_multipart(url, key, fields, files):
    b = "----hom" + uuid.uuid4().hex
    body = bytearray()
    for name, val in fields.items():
        body += f"--{b}\r\nContent-Disposition: form-data; name=\"{name}\"\r\n\r\n{val}\r\n".encode()
    for name, path in files:
        body += (f"--{b}\r\nContent-Disposition: form-data; name=\"{name}\"; filename=\"{os.path.basename(path)}\"\r\n"
                 f"Content-Type: image/png\r\n\r\n").encode()
        body += open(path, "rb").read() + b"\r\n"
    body += f"--{b}--\r\n".encode()
    req = urllib.request.Request(url, data=bytes(body), method="POST",
                                 headers={"Authorization": "Bearer " + key, "Content-Type": "multipart/form-data; boundary=" + b})
    return urllib.request.urlopen(req, timeout=300)


def generate(key, name, prompt, refs):
    size = SIZES.get(name.split("/")[0], "1024x1024")
    if refs:
        fields = {"model": MODEL, "prompt": REF_NOTE + prompt, "size": size, "quality": "high", "n": "1"}
        resp = post_multipart("https://api.openai.com/v1/images/edits", key, fields,
                              [("image[]", os.path.join(ART, r)) for r in refs])
    else:
        resp = post_json("https://api.openai.com/v1/images/generations", key,
                         {"model": MODEL, "prompt": prompt, "size": size, "quality": "high", "n": 1})
    data = json.loads(resp.read())
    return base64.b64decode(data["data"][0]["b64_json"])


def main():
    args = sys.argv[1:]
    if not args:
        sys.exit(__doc__)
    if args[0] == "--models":
        req = urllib.request.Request("https://api.openai.com/v1/models", headers={"Authorization": "Bearer " + api_key()})
        ids = sorted(m["id"] for m in json.loads(urllib.request.urlopen(req, timeout=60).read())["data"])
        for i in ids:
            if "image" in i or "dall" in i:
                print(i)
        return
    md = args[0]
    force, dry = "--force" in args, "--dry" in args
    only = None
    if "--only" in args:
        only = set(args[args.index("--only") + 1].split(","))
    # a szereplőkártyák készülnek először, hogy a többi kép referenciaként használhassa őket
    items = sorted(parse(md), key=lambda it: 0 if it[0].startswith("cards/c_") else 1)
    key = None if dry else api_key()
    done = 0
    for name, prompt in items:
        if only and name not in only:
            continue
        out = os.path.join(ART, name + ".png")
        if os.path.exists(out) and not force:
            continue
        refs = refs_for(name, prompt)
        print(f"-> {name}  (refs: {', '.join(refs) or '-'})", flush=True)
        if dry:
            continue
        for attempt in range(3):
            try:
                png = generate(key, name, prompt, refs)
                os.makedirs(os.path.dirname(out), exist_ok=True)
                open(out, "wb").write(png)
                done += 1
                print(f"   kész: {name}.png ({len(png) // 1024} KB)", flush=True)
                break
            except urllib.error.HTTPError as e:
                msg = e.read().decode(errors="replace")[:400]
                print(f"   HIBA {e.code}: {msg}", flush=True)
                if e.code in (400, 401, 403) or "insufficient_quota" in msg or "billing" in msg:
                    sys.exit(1)
                time.sleep(20 * (attempt + 1))
            except Exception as e:  # hálózati hiba: újrapróbálja
                print(f"   HIBA: {e}", flush=True)
                time.sleep(20 * (attempt + 1))
    print(f"Összesen elkészült: {done}")


if __name__ == "__main__":
    main()
