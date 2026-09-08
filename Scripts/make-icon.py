#!/usr/bin/env python3
"""앱 아이콘 생성기.

디자인 도구 없이 아이콘을 다시 만들 수 있도록 남겨둔다.
색이나 막대 배치를 바꾸고 싶으면 아래 VARIANTS를 고친 뒤 다시 실행하면 된다.

    python3 Scripts/make-icon.py            # 세 가지 시안을 build/icons/ 에 생성
    python3 Scripts/make-icon.py ink        # 고른 시안을 에셋 카탈로그에 설치

의존성 없음(표준 라이브러리만). 2배 크기로 그린 뒤 절반으로 줄여 계단현상을 없앤다.
"""
import os
import struct
import sys
import zlib

SIZE = 1024
SS = 2  # 슈퍼샘플링 배율

# 막대 배치. (폭, 액센트 여부) — 폭은 상대 단위다.
# 홈 화면에서 60pt로 줄어들어도 읽히도록 개수를 적게, 굵게 잡았다.
BARS = [(8, True), (4, False), (12, False), (5, False), (7, False)]
GAP = 5
BAR_AREA_W = 0.66   # 아이콘 폭 대비 막대 전체 폭
BAR_AREA_H = 0.56   # 아이콘 높이 대비 막대 높이

VARIANTS = {
    # 이름: (배경, 막대, 액센트 막대)
    "ink": ((0x12, 0x14, 0x1A), (0xFF, 0xFF, 0xFF), (0x5C, 0x7C, 0xFA)),
    "paper": ((0xF4, 0xF5, 0xF7), (0x17, 0x19, 0x1F), (0x3B, 0x5B, 0xDB)),
    "blue": ((0x33, 0x52, 0xD9), (0xFF, 0xFF, 0xFF), (0x12, 0x14, 0x1A)),
}


def fill_rounded_rect(buf, width, x0, y0, x1, y1, radius, color):
    """행 단위로 x 구간을 계산해 채운다. 픽셀마다 도는 것보다 훨씬 빠르다."""
    packed = bytes(color)
    for y in range(max(0, y0), min(len(buf) // (width * 3), y1)):
        inset = 0
        # 위아래 끝에서만 둥글게 깎는다
        for edge in (y0 + radius - y, y - (y1 - 1 - radius)):
            if edge > 0:
                inset = max(inset, radius - int((radius * radius - edge * edge) ** 0.5))
        left, right = x0 + inset, x1 - inset
        if right <= left:
            continue
        start = (y * width + left) * 3
        buf[start:start + (right - left) * 3] = packed * (right - left)


def render(background, bar_color, accent_color):
    width = SIZE * SS
    buf = bytearray(bytes(background) * (width * width))

    total_units = sum(w for w, _ in BARS) + GAP * (len(BARS) - 1)
    unit = (width * BAR_AREA_W) / total_units
    bar_height = int(width * BAR_AREA_H)
    y0 = (width - bar_height) // 2
    x = (width - width * BAR_AREA_W) / 2
    radius = int(unit * 1.2)

    for bar_units, is_accent in BARS:
        bar_width = bar_units * unit
        fill_rounded_rect(
            buf, width,
            int(round(x)), y0, int(round(x + bar_width)), y0 + bar_height,
            min(radius, int(bar_width // 2)),
            accent_color if is_accent else bar_color,
        )
        x += bar_width + GAP * unit
    return downsample(buf, width)


def downsample(buf, width):
    """SS배 크기를 원래 크기로 평균내며 줄인다. 이게 안티에일리어싱 역할을 한다."""
    out = bytearray(SIZE * SIZE * 3)
    for y in range(SIZE):
        rows = [(y * SS + dy) * width * 3 for dy in range(SS)]
        for x in range(SIZE):
            base = x * SS * 3
            for channel in range(3):
                total = 0
                for row in rows:
                    for dx in range(SS):
                        total += buf[row + base + dx * 3 + channel]
                out[(y * SIZE + x) * 3 + channel] = total // (SS * SS)
    return out


def write_png(path, pixels):
    def chunk(tag, data):
        body = tag + data
        return struct.pack(">I", len(data)) + body + struct.pack(">I", zlib.crc32(body))

    raw = b"".join(
        b"\x00" + bytes(pixels[y * SIZE * 3:(y + 1) * SIZE * 3]) for y in range(SIZE)
    )
    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9))
    png += chunk(b"IEND", b"")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb") as f:
        f.write(png)
    return path


def main():
    chosen = sys.argv[1] if len(sys.argv) > 1 else None
    if chosen and chosen not in VARIANTS:
        raise SystemExit(f"모르는 시안: {chosen}. 가능한 값: {', '.join(VARIANTS)}")

    targets = {chosen: VARIANTS[chosen]} if chosen else VARIANTS
    for name, colors in targets.items():
        pixels = render(*colors)
        if chosen:
            path = "Sources/App/Resources/Assets.xcassets/AppIcon.appiconset/icon-1024.png"
        else:
            path = f"build/icons/icon-{name}.png"
        print("생성:", write_png(path, pixels))


if __name__ == "__main__":
    main()
