# Mélységtérkép a festett kamraképekhez (Depth Anything V2 small, ONNX).
# Telepítés: pip install onnxruntime numpy pillow
# Modell: https://huggingface.co/onnx-community/depth-anything-v2-small (onnx/model.onnx)
# Használat (az assets/art/rooms mappában): python make_depth.py <model.onnx> . room_hall.png ...
import sys, os
import numpy as np
import onnxruntime as ort
from PIL import Image, ImageFilter

model, outdir = sys.argv[1], sys.argv[2]
files = sys.argv[3:]
sess = ort.InferenceSession(model, providers=["CPUExecutionProvider"])
inp = sess.get_inputs()[0].name
mean = np.array([0.485, 0.456, 0.406], np.float32)
std = np.array([0.229, 0.224, 0.225], np.float32)
for f in files:
    im = Image.open(f).convert("RGB")
    w, h = im.size
    H = 518
    W = int(round(H * w / h / 14.0)) * 14
    x = np.asarray(im.resize((W, H), Image.BICUBIC), np.float32) / 255.0
    x = ((x - mean) / std).transpose(2, 0, 1)[None]
    d = sess.run(None, {inp: x})[0]
    d = np.squeeze(d).astype(np.float32)
    lo, hi = np.percentile(d, 1), np.percentile(d, 99)
    d = np.clip((d - lo) / max(hi - lo, 1e-6), 0, 1)
    img = Image.fromarray((d * 255).astype(np.uint8), "L").resize((w // 2, h // 2), Image.BICUBIC)
    img = img.filter(ImageFilter.GaussianBlur(2))
    name = os.path.splitext(os.path.basename(f))[0] + "_depth.png"
    img.save(os.path.join(outdir, name))
    print(name, img.size, sess.get_inputs()[0].shape)
