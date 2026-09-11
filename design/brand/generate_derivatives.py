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


def remove_black_background(im_rgb, low=45, high=110, crop_padding=20):
    """Usada no wordmark atual: arte cromada/teal com brilho proprio sobre um
    fundo preto solido, com um glow radial largo em volta das letras (nao um
    simbolo com letras escuras sobre fundo claro como a versao anterior --
    por isso NAO usa mais corte por brilho).

    Alpha por luminancia (rampa suave de `low` a `high`), nao flood-fill
    binario: um corte binario (dentro/fora de um raio de tolerancia da cor
    preta) deixava a borda do glow com um contorno duro e irregular -- lia
    como uma "nuvem" preta chapada por cima de fundo claro, em vez de um
    brilho. A rampa suave faz esse limite desaparecer gradualmente qualquer
    que seja o fundo (testado sobre branco e sobre preto). `low`/`high` altos
    de proposito: cortam a maior parte do bloom difuso do fundo, deixando so
    um halo justo perto das letras -- o glow mais amplo da arte original nao
    sobrevive por bem sem fundo escuro fixo por tras.

    Corta pro bounding box do conteudo visivel (+ padding) pra nao sobrar
    moldura transparente enorme quando exibido por altura fixa. A arte ja tem
    contraste proprio em qualquer fundo, entao BrandWordmark NAO aplica mais
    inversao de cor no dark mode (isso so fazia sentido pra tinta solida da
    versao anterior)."""
    arr = np.array(im_rgb).astype(float)
    luma = 0.299 * arr[:, :, 0] + 0.587 * arr[:, :, 1] + 0.114 * arr[:, :, 2]
    alpha = np.clip((luma - low) / (high - low) * 255, 0, 255).astype(np.uint8)
    rgba = np.dstack([arr.astype(np.uint8), alpha])
    out = Image.fromarray(rgba, mode="RGBA")

    ys, xs = np.where(alpha > 20)
    h, w = alpha.shape
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
# cropped to content -- see remove_black_background. The biggest usage in
# the app is BrandWordmark(height: 76) -- at typical 3x device pixel ratio
# that is ~228px. Shipping the full-resolution crop (643px tall) made the
# app downscale it live by >8x every frame; Flutter's default bilinear
# filtering (no mipmaps) muddies thin bright strokes at that ratio -- the
# chrome letters and teal glow read as a dull grey smudge instead of
# bright metal. Baking the resize down to ~3x the largest real usage with
# LANCZOS here (once, at build time) keeps the live scale factor small
# enough that bilinear filtering doesn't lose the highlights.
escrito_transparent = remove_black_background(escrito_rgba.convert("RGB"))
target_h = 260
scale = target_h / escrito_transparent.height
escrito_resized = escrito_transparent.resize(
    (round(escrito_transparent.width * scale), target_h), Image.LANCZOS
)
escrito_resized.save(os.path.join(ASSETS_DIR, "wordmark.png"), optimize=True)

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
