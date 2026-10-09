"""Build a TrackMaps outline from an F1 static-archive Position.z.jsonStream.

Picks the fastest closed loop driven by any car (a flying lap, so no pit lane),
resamples it to a fixed spacing and writes it in the bundled TrackMaps
convention, where Y is NEGATED relative to F1 position coordinates.
"""
import argparse, base64, json, math, urllib.request, zlib

UA = {'User-Agent': 'BestHTTP'}


def load_stream(path_or_url):
    if path_or_url.startswith('http'):
        raw = urllib.request.urlopen(urllib.request.Request(path_or_url, headers=UA), timeout=120).read().decode('utf-8-sig')
    else:
        raw = open(path_or_url, encoding='utf-8-sig').read()
    samples = {}  # car -> [(t_seconds, x, y)]
    for line in raw.splitlines():
        line = line.strip()
        if len(line) < 13:
            continue
        obj = json.loads(zlib.decompress(base64.b64decode(json.loads(line[12:])), -15))
        for item in obj.get('Position', []):
            ts = item['Timestamp']
            hh, mm, ss = ts.split('T')[1].rstrip('Z').split(':')
            t = int(hh) * 3600 + int(mm) * 60 + float(ss)
            for car, c in item.get('Entries', {}).items():
                if c.get('Status') != 'OnTrack' or (c.get('X', 0) == 0 and c.get('Y', 0) == 0):
                    continue
                samples.setdefault(car, []).append((t, c['X'], c['Y']))
    return samples


def fastest_loop(samples, min_len, close_dist):
    best = None  # (duration, points)
    for car, pts in samples.items():
        for i in range(0, len(pts), 8):
            t0, x0, y0 = pts[i]
            if i + 2 >= len(pts):
                break
            h0 = math.atan2(pts[i + 2][2] - y0, pts[i + 2][1] - x0)
            length = 0.0
            for j in range(i + 1, len(pts)):
                t, x, y = pts[j]
                px, py = pts[j - 1][1], pts[j - 1][2]
                step = math.hypot(x - px, y - py)
                if step > 1500 or t - pts[j - 1][0] > 3:  # gap in data
                    break
                length += step
                # Require the same heading as the start so a figure-eight
                # (Suzuka) doesn't "close" at its crossover.
                h = math.atan2(y - py, x - px)
                dh = abs((h - h0 + math.pi) % (2 * math.pi) - math.pi)
                if (length > min_len and math.hypot(x - x0, y - y0) < close_dist
                        and dh < math.radians(30)):
                    dur = t - t0
                    if best is None or dur < best[0]:
                        best = (dur, [(p[1], p[2]) for p in pts[i:j + 1]], car, length)
                    break
    return best


def resample(points, spacing):
    out = [points[0]]
    carry = 0.0
    for (ax, ay), (bx, by) in zip(points, points[1:]):
        seg = math.hypot(bx - ax, by - ay)
        d = spacing - carry
        while d <= seg:
            f = d / seg
            out.append((ax + (bx - ax) * f, ay + (by - ay) * f))
            d += spacing
        carry = seg - (d - spacing)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('source', help='Position.z.jsonStream path or URL')
    ap.add_argument('--out', required=True)
    ap.add_argument('--circuit-key', type=int, required=True)
    ap.add_argument('--circuit-name', required=True)
    ap.add_argument('--location', required=True)
    ap.add_argument('--year', type=int, required=True)
    ap.add_argument('--rotation', type=int, default=0)
    ap.add_argument('--min-length', type=float, default=30000)  # 1/10 m
    ap.add_argument('--spacing', type=float, default=60)
    args = ap.parse_args()

    best = fastest_loop(load_stream(args.source), args.min_length, 300)
    if best is None:
        raise SystemExit('no closed loop found')
    dur, pts, car, length = best
    pts = resample(pts, args.spacing)
    print(f'car {car}: {dur:.1f}s, {length / 10000:.3f} km, {len(pts)} points')
    json.dump({
        'circuitKey': args.circuit_key,
        'circuitName': args.circuit_name,
        'location': args.location,
        'year': args.year,
        'rotation': args.rotation,
        'corners': [], 'marshalLights': [], 'marshalSectors': [], 'miniSectorsIndexes': [],
        'x': [round(x) for x, _ in pts],
        'y': [-round(y) for _, y in pts],  # bundled convention: Y negated
    }, open(args.out, 'w'), indent=2)


if __name__ == '__main__':
    main()
