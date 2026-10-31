# Spinning donut, classic donut.c algorithm (Dmitry Sokolov, 2006), Python port.
# Rendered with 24-bit color; size adapts to the pane.
import math, shutil, sys, time

CHARS = ".,-~:;=!*#$@"
ESC = "\x1b["

def color_for(i):
    if i >= 9:
        return "38;2;232;226;209"   # near white
    if i >= 5:
        return "38;2;167;192;128"   # green
    return "38;2;131;192;146"       # aqua

def main():
    A = B = 0.0
    sys.stdout.write(ESC + "2J")
    while True:
        cols, rows = shutil.get_terminal_size((80, 30))
        W = max(24, min(150, cols - 2))
        H = max(12, min(56, rows - 2))
        zb = [0.0] * (W * H)
        buf = [' '] * (W * H)

        j = 0.0
        while j < 6.283:
            ct, st = math.cos(j), math.sin(j)
            i = 0.0
            while i < 6.283:
                cp, sp = math.cos(i), math.sin(i)
                h = cp * ct + 1.0
                d = 1.0 / (sp * h * math.sin(A) + st * math.cos(A) + 5.0)
                t = sp * h * math.cos(A) - st * math.sin(A)
                x = int(W / 2 + W * 0.86 * d * (cp * sp * math.sin(B) - t * math.cos(B)))
                y = int(H / 2 + H * 0.94 * d * (cp * sp * math.cos(B) + t * math.sin(B)))
                n = int(8 * ((st * math.sin(A) - sp * ct * math.cos(A)) * math.cos(B)
                             - sp * ct * math.sin(A) - st * math.cos(A)
                             - cp * ct * math.sin(B)))
                if 0 <= x < W and 0 <= y < H:
                    o = x + W * y
                    if d > zb[o]:
                        zb[o] = d
                        buf[o] = CHARS[max(0, min(11, n))]
                i += 0.024
            j += 0.050

        out = [ESC + "H"]
        for y in range(H):
            row = []
            for x in range(W):
                c = buf[x + W * y]
                if c == ' ':
                    row.append(' ')
                else:
                    row.append(ESC + color_for(CHARS.index(c)) + "m" + c + ESC + "0m")
            out.append("".join(row) + "\n")
        sys.stdout.write("".join(out))
        sys.stdout.flush()

        A += 0.04
        B += 0.02
        time.sleep(0.008)

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        pass
