"""
Gera derivados tecnicos dos assets oficiais (logo.png, escrito.png) SEM
alterar os originais em design/brand/. controle.png e o mark antigo (icone
de controle) e nao e mais usado por este script -- ficou soterrado aqui so
como referencia historica.

- assets/brand/            -> imagens exibidas em runtime pelo app (Image.asset)
- design/brand/generated/  -> fontes usadas so em build-time pelos geradores de
                              icon/splash (flutter_launcher_icons /
                              flutter_native_splash); nao entram no bundle.

So faz resize/pad sobre fundo branco identico ao das artes originais -- nunca
recorta, redesenha ou distorce o desenho.
"""
from PIL import Image
import numpy as np
import os
from collections import deque

BRAND_DIR = os.path.dirname(os.path.abspath(__file__))
ASSETS_DIR = os.path.join(BRAND_DIR, "..", "..", "assets", "brand")
GENERATED_DIR = os.path.join(BRAND_DIR, "generated")
WHITE = (255, 255, 255)


def load(name):
    return Image.open(os.path.join(BRAND_DIR, name)).convert("RGB")


def pad_to_square_white(im, canvas_size, content_fraction):
    """Resize im (keeping aspect ratio) so its own bounding box width becomes
    roughly `content_fraction` of canvas_size, then center it on a white
    canvas_size x canvas_size canvas. Never crops or redraws -- only scales
    the whole source image and adds matching white margin."""
    src_w, src_h = im.size
    scale = (canvas_size * content_fraction) / src_w
    new_w, new_h = round(src_w * scale), round(src_h * scale)
    resized = im.resize((new_w, new_h), Image.LANCZOS)
    canvas = Image.new("RGB", (canvas_size, canvas_size), WHITE)
    offset = ((canvas_size - new_w) // 2, (canvas_size - new_h) // 2)
    canvas.paste(resized, offset)
    return canvas


def remove_black_background(im_rgb, tolerance=18, crop_padding=20):
    """Usada no wordmark atual: arte cromada/teal com brilho proprio sobre um
    fundo preto solido (nao um simbolo com letras escuras sobre fundo claro
    como a versao anterior -- por isso NAO usa mais corte por brilho).
    Flood-fill a partir das bordas da imagem remove só o preto contíguo à
    moldura, preservando o glow teal do meio (que não é preto puro) como um
    halo intencional. Depois corta pro bounding box do conteudo visivel
    (+ padding) pra nao sobrar moldura transparente enorme quando exibido
    por altura fixa. A arte ja tem contraste proprio em qualquer fundo, entao
    BrandWordmark NAO aplica mais inversao de cor no dark mode (isso so fazia
    sentido pra tinta solida da versao anterior)."""
    arr = np.array(im_rgb).astype(int)
    h, w, _ = arr.shape
    visited = np.zeros((h, w), dtype=bool)
    black = np.array([0, 0, 0])

    def similar(p):
        return (
            abs(p[0] - black[0]) <= tolerance
            and abs(p[1] - black[1]) <= tolerance
            and abs(p[2] - black[2]) <= tolerance
        )

    queue = deque()
    border_pixels = (
        [(0, x) for x in range(w)]
        + [(h - 1, x) for x in range(w)]
        + [(y, 0) for y in range(h)]
        + [(y, w - 1) for y in range(h)]
    )
    for y, x in border_pixels:
        if not visited[y, x] and similar(arr[y, x]):
            visited[y, x] = True
            queue.append((y, x))

    while queue:
        y, x = queue.popleft()
        for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            ny, nx = y + dy, x + dx
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx] and similar(arr[ny, nx]):
                visited[ny, nx] = True
                queue.append((ny, nx))

    alpha = np.where(visited, 0, 255).astype(np.uint8)
    rgba = np.dstack([arr.astype(np.uint8), alpha])
    out = Image.fromarray(rgba, mode="RGBA")

    ys, xs = np.where(alpha > 10)
    x0, x1 = max(0, xs.min() - crop_padding), min(w, xs.max() + crop_padding)
    y0, y1 = max(0, ys.min() - crop_padding), min(h, ys.max() + crop_padding)
    return out.crop((x0, y0, x1, y1))


def fit_width_white(im, canvas_w, canvas_h, target_w):
    src_w, src_h = im.size
    scale = target_w / src_w
    new_w, new_h = round(src_w * scale), round(src_h * scale)
    resized = im.resize((new_w, new_h), Image.LANCZOS)
    canvas = Image.new("RGB", (canvas_w, canvas_h), WHITE)
    offset = ((canvas_w - new_w) // 2, (canvas_h - new_h) // 2)
    canvas.paste(resized, offset)
    return canvas


os.makedirs(ASSETS_DIR, exist_ok=True)
os.makedirs(GENERATED_DIR, exist_ok=True)

escrito_rgba = Image.open(os.path.join(BRAND_DIR, "escrito.png")).convert("RGBA")
logo = load("logo.png")

# ---- Runtime assets (bundled via pubspec assets:) ----

# Icon mark used inline by BrandMark (nav rail, splash widget, auth forms).
# logo.png is already a full-bleed 1024x1024 squircle (corners cleared to
# transparent, which .convert("RGB") above flattens back to the white they
# were exported with) -- downscaling to 512 is plenty for anything up to
# ~170dp on a 3x display, avoids decoding a much bigger PNG just to show it
# at 32-72dp.
logo.resize((512, 512), Image.LANCZOS).save(os.path.join(ASSETS_DIR, "icon.png"), optimize=True)

# Wordmark: solid black frame cut to transparent, teal glow kept as a halo,
# cropped to content -- see remove_black_background.
escrito_transparent = remove_black_background(escrito_rgba.convert("RGB"))
escrito_transparent.save(os.path.join(ASSETS_DIR, "wordmark.png"), optimize=True)

# No separate splash.png: BrandAssets.splashMark is null on purpose (see its
# doc comment) -- SplashPage composes the icon + wordmark above live from
# assets/brand/icon.png and assets/brand/wordmark.png instead of a flattened
# lockup that can go stale on its own.

# ---- Build-time-only sources (flutter_launcher_icons / flutter_native_splash) ----

# General app icon source (iOS + Android legacy + Web favicon/PWA). iOS/Web
# don't apply an aggressive safe-zone circle like Android adaptive icons do,
# and logo.png already fills its own 1024x1024 frame, so no extra shrink.
icon_general = pad_to_square_white(logo, 1024, content_fraction=1.0)
icon_general.save(os.path.join(GENERATED_DIR, "icon_general_1024.png"), optimize=True)

# Android adaptive icon foreground: must survive circular/squircle/rounded-
# square launcher masks, which only guarantee the inner ~66% safe circle.
# Content pinned to ~60% width for comfortable margin under any mask shape.
icon_adaptive_fg = pad_to_square_white(logo, 1024, content_fraction=0.6)
icon_adaptive_fg.save(os.path.join(GENERATED_DIR, "icon_adaptive_fg_1024.png"), optimize=True)

# Native splash source: some margin so Android 12's own splash-icon safe
# zone (similar ~66% constraint) doesn't clip the wordmark under the pad.
splash_source = pad_to_square_white(logo, 1024, content_fraction=0.72)
splash_source.save(os.path.join(GENERATED_DIR, "splash_source_1024.png"), optimize=True)

print("Generated:")
for f in sorted(os.listdir(ASSETS_DIR)):
    print(" assets/brand/" + f)
for f in sorted(os.listdir(GENERATED_DIR)):
    print(" design/brand/generated/" + f)
