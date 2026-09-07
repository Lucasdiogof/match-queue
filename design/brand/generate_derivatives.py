"""
Gera derivados tecnicos dos assets oficiais (controle.png, escrito.png,
logo.png) SEM alterar os originais em design/brand/.

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


def remove_white_background(im_rgb, low=200, high=250):
    """So usada no wordmark: letras quase pretas sobre fundo quase branco,
    com um vao limpo entre as duas faixas de brilho (confirmado por
    histograma) -- corte de alpha por brilho fica limpo aqui. NUNCA usar no
    controle: o corpo dele e branco, o mesmo truque comeria a propria arte.
    Ficar transparente sozinho deixaria as letras pretas invisiveis no dark
    mode -- por isso BrandWordmark aplica um ColorFiltered de inversao so
    no dark, em vez de nao remover o fundo."""
    arr = np.array(im_rgb).astype(np.float64)
    brightness = arr.min(axis=2)
    alpha = np.clip((high - brightness) / (high - low), 0.0, 1.0) * 255.0
    rgba = np.dstack([arr, alpha]).astype(np.uint8)
    return Image.fromarray(rgba, mode="RGBA")


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

controle = load("controle.png")
escrito_rgba = Image.open(os.path.join(BRAND_DIR, "escrito.png")).convert("RGBA")
logo = load("logo.png")

# ---- Runtime assets (bundled via pubspec assets:) ----

# Icon mark used inline by BrandMark (nav rail, splash widget, auth forms).
# Original content already has ~90% width fill; downscaling to 512 is plenty
# for anything up to ~170dp on a 3x display, avoids decoding a 1.2MB/1254px
# PNG just to show it at 32-72dp.
controle.resize((512, 512), Image.LANCZOS).save(os.path.join(ASSETS_DIR, "icon.png"), optimize=True)

# Wordmark: background cut to transparent (histogram-verified clean gap
# between the near-black letterforms and the near-white background --
# see remove_white_background). BrandWordmark handles dark-mode legibility
# with a ColorFiltered invert instead of keeping a background card.
escrito_transparent = remove_white_background(escrito_rgba.convert("RGB"))
escrito_transparent.save(os.path.join(ASSETS_DIR, "wordmark.png"), optimize=True)

# Splash lockup shown by the in-app SplashPage widget (not full-bleed native
# splash) -- 640px is comfortable for the size it's actually displayed at.
logo.resize((640, 640), Image.LANCZOS).save(os.path.join(ASSETS_DIR, "splash.png"), optimize=True)

# ---- Build-time-only sources (flutter_launcher_icons / flutter_native_splash) ----

# General app icon source (iOS + Android legacy + Web favicon/PWA). iOS/Web
# don't apply an aggressive safe-zone circle like Android adaptive icons do,
# so a modest ~8% margin (vs. the original's ~4.7%) is enough breathing room.
icon_general = pad_to_square_white(controle, 1024, content_fraction=0.84)
icon_general.save(os.path.join(GENERATED_DIR, "icon_general_1024.png"), optimize=True)

# Android adaptive icon foreground: must survive circular/squircle/rounded-
# square launcher masks, which only guarantee the inner ~66% safe circle.
# Content pinned to ~58% width for comfortable margin under any mask shape.
icon_adaptive_fg = pad_to_square_white(controle, 1024, content_fraction=0.58)
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
