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
from PIL import Image, ImageFilter
import numpy as np
import os

BRAND_DIR = os.path.dirname(os.path.abspath(__file__))
ASSETS_DIR = os.path.join(BRAND_DIR, "..", "..", "assets", "brand")
GENERATED_DIR = os.path.join(BRAND_DIR, "generated")
WHITE = (255, 255, 255)
# Mesmo tom de fundo escuro do proprio app (AppColors.darkBackground) --
# nao um verde generico: e o pixel real que o app pinta atras de tudo no
# tema escuro, entao a moldura do icone bate com a marca de verdade em vez
# de so "parecer verde".
ICON_DARK_BG = (0x08, 0x0A, 0x09)


def load_on(name, bg_color):
    """RGBA source alpha-composited onto bg_color, never a naive
    .convert("RGB") (which keeps whatever RGB happens to sit under a
    transparent pixel -- logo.png's transparent corners are black
    underneath, not white, so that naive convert was silently baking a
    black border into every derivative that used it).

    Matters even when the canvas around it is later overscaled past the
    edge (content_fraction > 1, full bleed): once the source is larger
    than the canvas, the canvas's OWN background color never shows at
    all -- what shows at the very corners is the SOURCE's own margin,
    scaled up. Composite it onto the same color the canvas would have
    used, or that margin shows as a visible ring in whatever color this
    was composited onto instead (white, if using the white-card
    variant)."""
    im = Image.open(os.path.join(BRAND_DIR, name)).convert("RGBA")
    bg = Image.new("RGB", im.size, bg_color)
    bg.paste(im, mask=im.split()[-1])
    return bg


def load(name):
    """White-backed variant -- for the white-card BrandMark usage, where a
    white margin is the actual design (see BrandMark's own doc comment)."""
    return load_on(name, WHITE)


def load_rgba(name):
    """Same source, alpha kept intact -- for derivatives that must stay
    transparent (the splash source), where baking a white square behind the
    squircle would be just as wrong as the black border it replaces."""
    return Image.open(os.path.join(BRAND_DIR, name)).convert("RGBA")


def pad_to_square(im, canvas_size, content_fraction, bg_color):
    """Resize im (keeping aspect ratio) so its own bounding box width becomes
    roughly `content_fraction` of canvas_size, then center it on a
    canvas_size x canvas_size canvas filled with bg_color. Never crops or
    redraws -- only scales the whole source image and adds matching margin.
    content_fraction > 1 deliberately overscales past the canvas edge (full
    bleed) instead of leaving a margin, since it's an icon and the OS masks/
    crops it anyway -- a plain color margin behind a slightly-inset badge
    graphic reads as an unwanted border, not as the icon's own design."""
    src_w, src_h = im.size
    scale = (canvas_size * content_fraction) / src_w
    new_w, new_h = round(src_w * scale), round(src_h * scale)
    resized = im.resize((new_w, new_h), Image.LANCZOS)
    canvas = Image.new("RGB", (canvas_size, canvas_size), bg_color)
    offset = ((canvas_size - new_w) // 2, (canvas_size - new_h) // 2)
    canvas.paste(resized, offset)
    return canvas


def pad_to_square_transparent(im_rgba, canvas_size, content_fraction):
    """Same resize-and-center as pad_to_square_white, but onto a fully
    transparent canvas instead of a white one -- for native splash screens,
    which composite the image over their own background color and would
    show a wrong/visible edge around any solid fill we added ourselves."""
    src_w, src_h = im_rgba.size
    scale = (canvas_size * content_fraction) / src_w
    new_w, new_h = round(src_w * scale), round(src_h * scale)
    resized = im_rgba.resize((new_w, new_h), Image.LANCZOS)
    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    offset = ((canvas_size - new_w) // 2, (canvas_size - new_h) // 2)
    canvas.paste(resized, offset, mask=resized.split()[-1])
    return canvas


def remove_black_background(
    im_rgb,
    bright_low=150,
    bright_high=185,
    teal_low=25,
    teal_high=60,
    peak_spread=3,
    crop_padding=15,
):
    """Usada no wordmark atual: arte cromada/teal com brilho proprio sobre um
    fundo preto solido, com um glow radial LARGO e difuso em volta das letras
    -- nao um simbolo com letras escuras sobre fundo claro como a versao
    anterior, por isso nao e corte por chroma-key de uma cor so.

    Duas tentativas anteriores erraram pro lado contrario:
    1. Flood-fill binario a partir da borda (so remove preto continguo):
       qualquer pixel do glow que nao fosse "perto o suficiente" do preto
       ficava 100% opaco -- contorno duro e irregular, lia como uma nuvem
       preta chapada.
    2. Rampa suave de alpha por luminancia sobre TODO o range de brilho:
       reintroduz o mesmo bloom difuso so que com borda macia -- ainda uma
       nuvem visivel, so com menos serrilhado.

    A saida real e reconhecer que "letra" e "glow difuso de fundo" nao se
    separam por um unico corte de brilho: o bloom do fundo tem o MESMO tom
    (cinza claro / branco) que a carroceria cromada das letras, so que
    espalhado por uma area enorme. Em vez de brilho absoluto, dois sinais
    mais especificos:
    - `bright_*`: cinza/branco quase neutro E bem acima do bloom mais forte
      (que nunca chega no branco puro da chapa cromada) -- pega corpo das
      letras e do texto, ignora o glow.
    - `teal_*`: canais G bem acima de R/B (o ciano da arte), captura QUEUE,
      as linhas do traco e os dois pontos de brilho ciano no topo -- sem
      depender de brilho absoluto, so da cor.

    Traco fino (o "PLAY TOGETHER") tem so 1-2px de nucleo brilhante depois
    do anti-aliasing original, mais fino que a rampa `bright_*` sozinha
    capturava por inteiro -- por isso o brilho e espalhado (`peak_spread`,
    um max-filter) antes do corte: qualquer pixel a poucos px de um pico
    de brilho conta como parte do traco, sem alargar perceptivelmente o
    contorno das letras grandes (que ja eram solidas).

    Corta pro bounding box do conteudo visivel (+ padding). A arte ja tem
    contraste proprio em qualquer fundo, entao BrandWordmark NAO aplica
    inversao de cor no dark mode."""
    arr = np.array(im_rgb).astype(float)
    luma = 0.299 * arr[:, :, 0] + 0.587 * arr[:, :, 1] + 0.114 * arr[:, :, 2]
    teal_chroma = arr[:, :, 1] - np.maximum(arr[:, :, 0], arr[:, :, 2])

    luma_img = Image.fromarray(np.clip(luma, 0, 255).astype(np.uint8), mode="L")
    luma_spread = np.array(luma_img.filter(ImageFilter.MaxFilter(peak_spread))).astype(
        float
    )

    bright_alpha = np.clip(
        (luma_spread - bright_low) / (bright_high - bright_low) * 255, 0, 255
    )
    teal_alpha = np.clip(
        (teal_chroma - teal_low) / (teal_high - teal_low) * 255, 0, 255
    )
    alpha = np.clip(np.maximum(bright_alpha, teal_alpha), 0, 255).astype(np.uint8)

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
logo_rgba = load_rgba("logo.png")

# ---- Runtime assets (bundled via pubspec assets:) ----

# Icon mark used inline by BrandMark (nav rail, splash widget, auth forms).
# logo.png is a squircle badge with a few % of transparent margin around
# it; load() composites that onto white for this white-card usage (see
# BrandMark's own comment on why it renders as a bordered card, not a raw
# squircle). Downscaling to 512 is plenty for anything up to ~170dp on a
# 3x display, avoids decoding a much bigger PNG just to show it at 32-72dp.
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

# General app icon source (iOS + Android legacy + Web favicon/PWA). iOS
# masks/rounds this itself (never round it here) and shows no background
# color at all outside the mask, so a plain color margin behind the badge
# would look like an unwanted border around it -- logo.png's own ~6% margin
# around its rounded-square art gets cropped away by overscaling slightly
# past the canvas edge (full bleed) instead of kept as visible padding.
icon_general_source = load_on("logo.png", ICON_DARK_BG)
icon_general = pad_to_square(
    icon_general_source, 1024, content_fraction=1.08, bg_color=ICON_DARK_BG
)
icon_general.save(os.path.join(GENERATED_DIR, "icon_general_1024.png"), optimize=True)

# Android adaptive icon foreground: TRANSPARENT outside the art (the dark
# background comes from adaptive_icon_background in pubspec.yaml, a separate
# layer Android composites behind this one -- filling it here would just be
# a second, redundant background). adaptive_icon_foreground_inset is set to
# 0 in pubspec.yaml, so this content_fraction is the ONLY sizing control:
# ~66% matches Android's guaranteed-visible safe-zone circle (66dp of the
# 108dp full asset) without an extra tool-side inset shrinking it further,
# which is what made the mark read as too small/off-center before.
icon_adaptive_fg = pad_to_square_transparent(logo_rgba, 1024, content_fraction=0.66)
icon_adaptive_fg.save(os.path.join(GENERATED_DIR, "icon_adaptive_fg_1024.png"), optimize=True)

# Native splash source: transparent, not color-padded -- flutter_native_splash
# already paints its own background color behind it (color/color_dark in
# pubspec.yaml). A filled square here duplicated that background clumsily;
# a black one (the bug this replaced) showed as a border that was never
# supposed to exist. Same margin as before so Android 12's own splash-icon
# safe zone (~66% constraint) doesn't clip the wordmark under it.
splash_source = pad_to_square_transparent(logo_rgba, 1024, content_fraction=0.72)
splash_source.save(os.path.join(GENERATED_DIR, "splash_source_1024.png"), optimize=True)

print("Generated:")
for f in sorted(os.listdir(ASSETS_DIR)):
    print(" assets/brand/" + f)
for f in sorted(os.listdir(GENERATED_DIR)):
    print(" design/brand/generated/" + f)
