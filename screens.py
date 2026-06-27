"""NerdMiner-style screens rendered onto the 240x240 ST7789.

Each screen is a function (img, draw, data, fonts, ctx) -> None that draws a
full frame. Kept text-only (no emoji) so it renders cleanly with DejaVu fonts.
"""
import os
import socket
import subprocess

BG = (10, 10, 14)
ORANGE = (247, 147, 26)      # bitcoin orange
WHITE = (235, 235, 235)
GREEN = (0, 255, 163)
DIM = (130, 130, 140)
RED = (255, 80, 80)

W = H = 240


# ---------- formatting helpers ----------

def fmt_hashrate(hs):
    for unit, div in (("GH/s", 1e9), ("MH/s", 1e6), ("kH/s", 1e3)):
        if hs >= div:
            return f"{hs / div:.2f} {unit}"
    return f"{hs:.0f} H/s"


def fmt_suffix(value):
    """Big number -> short suffix form (e.g. 83.1T)."""
    for suffix, div in (("E", 1e18), ("P", 1e15), ("T", 1e12),
                        ("G", 1e9), ("M", 1e6), ("K", 1e3)):
        if value >= div:
            return f"{value / div:.1f}{suffix}"
    return f"{value:.0f}"


def fmt_uptime(seconds):
    seconds = int(seconds)
    d, rem = divmod(seconds, 86400)
    h, rem = divmod(rem, 3600)
    m, _ = divmod(rem, 60)
    if d:
        return f"{d}d {h}h {m}m"
    return f"{h:02d}h {m:02d}m"


def _centered(draw, font, text, y, fill):
    bbox = font.getbbox(text)
    w = bbox[2] - bbox[0]
    draw.text(((W - w) // 2, y), text, font=font, fill=fill)


def _header(draw, fonts, title, page_idx, page_count):
    draw.rectangle([(0, 0), (W - 1, 40)], fill=ORANGE)
    draw.text((10, 8), title, font=fonts["title"], fill=BG)
    dots = " ".join("o" if i == page_idx else "." for i in range(page_count))
    bbox = fonts["small"].getbbox(dots)
    draw.text((W - (bbox[2] - bbox[0]) - 10, 14), dots, font=fonts["small"], fill=BG)


# ---------- screens ----------

def screen_miner(img, draw, data, fonts, ctx):
    _header(draw, fonts, "MINER", ctx["page"], ctx["pages"])
    _centered(draw, fonts["small"], "local hashrate", 52, DIM)
    _centered(draw, fonts["big"], fmt_hashrate(data["hashrate_hs"]), 70, GREEN)

    acc, tot = data["accepted"], data["total"]
    rej = max(tot - acc, 0)
    draw.text((14, 130), "shares", font=fonts["small"], fill=DIM)
    draw.text((14, 148), f"{acc} ok / {rej} rej", font=fonts["body"],
              fill=WHITE if rej == 0 else RED)

    draw.text((14, 180), "pool hashrate", font=fonts["small"], fill=DIM)
    draw.text((14, 198), fmt_hashrate(data["pool_hashrate_hs"]),
              font=fonts["body"], fill=WHITE)


def screen_lottery(img, draw, data, fonts, ctx):
    _header(draw, fonts, "LOTTERY", ctx["page"], ctx["pages"])
    _centered(draw, fonts["small"], "best share difficulty", 50, DIM)
    _centered(draw, fonts["big"], fmt_suffix(data["best_share"]), 66, ORANGE)

    net = data["difficulty"]
    draw.text((14, 126), "network difficulty", font=fonts["small"], fill=DIM)
    draw.text((14, 144), fmt_suffix(net), font=fonts["body"], fill=WHITE)

    if net > 0 and data["best_share"] > 0:
        ratio = data["best_share"] / net
        pct = min(ratio * 100, 100.0)
        draw.text((14, 176), "block progress", font=fonts["small"], fill=DIM)
        draw.text((14, 194), f"{pct:.6f}%", font=fonts["body"], fill=GREEN)
    else:
        draw.text((14, 184), "waiting for first share...",
                  font=fonts["small"], fill=DIM)


def screen_bitcoin(img, draw, data, fonts, ctx):
    _header(draw, fonts, "BITCOIN", ctx["page"], ctx["pages"])
    fiat = data.get("fiat", "USD")
    price = data["price"]
    _centered(draw, fonts["small"], f"price ({fiat})", 54, DIM)
    price_txt = f"{price:,.0f}" if price else "--"
    _centered(draw, fonts["big"], price_txt, 72, GREEN)

    draw.text((14, 134), "block height", font=fonts["small"], fill=DIM)
    draw.text((14, 152), f"{data['block_height']:,}", font=fonts["body"], fill=ORANGE)

    draw.text((14, 184), "difficulty", font=fonts["small"], fill=DIM)
    draw.text((14, 202), fmt_suffix(data["difficulty"]), font=fonts["body"], fill=WHITE)


def _sys_metric(cmd_or_path, parse):
    try:
        return parse()
    except Exception:
        return "--"


def screen_system(img, draw, data, fonts, ctx):
    _header(draw, fonts, "SYSTEM", ctx["page"], ctx["pages"])

    def ip():
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            s.connect(("8.8.8.8", 80))
            return s.getsockname()[0]
        finally:
            s.close()

    def temp():
        with open("/sys/class/thermal/thermal_zone0/temp") as fh:
            return f"{int(fh.read().strip()) / 1000:.1f} C"

    def load():
        return os.getloadavg()[0]

    rows = [
        ("IP", _sys_metric(None, ip)),
        ("CPU temp", _sys_metric(None, temp)),
        ("load (1m)", _sys_metric(None, lambda: f"{load():.2f}")),
        ("session", fmt_uptime(ctx["uptime"])),
        ("pool", ctx["pool_name"]),
    ]
    y = 56
    for label, value in rows:
        draw.text((14, y), label, font=fonts["small"], fill=DIM)
        draw.text((110, y - 2), str(value), font=fonts["body"], fill=WHITE)
        y += 34


SCREENS = [screen_miner, screen_lottery, screen_bitcoin, screen_system]
