#!/usr/bin/env python3
"""Refresh the offline symbol-name catalog from SFSafeSymbols (MIT)."""
import concurrent.futures, json, pathlib, re, urllib.request
root = pathlib.Path(__file__).resolve().parents[1]
def read(url):
    return urllib.request.urlopen(url).read().decode()
files = json.loads(read('https://api.github.com/repos/SFSafeSymbols/SFSafeSymbols/contents/Sources/SFSafeSymbols/Symbols'))
urls = [f['download_url'] for f in files if re.fullmatch(r'SFSymbol\+\d+\.\d+\.swift', f['name'])]
with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
    names = sorted({n for source in pool.map(read, urls) for n in re.findall(r'rawValue: "([^"]+)"', source)})
assert len(names) > 4000, 'Unexpectedly small catalog'
(root / 'Sources/SymbolViewer/Resources/symbols.txt').write_text('\n'.join(names) + '\n')
(root / 'Sources/SymbolViewer/Resources/SFSafeSymbols-LICENSE.txt').write_text(read('https://raw.githubusercontent.com/SFSafeSymbols/SFSafeSymbols/stable/LICENSE'))
print(f'Wrote {len(names)} symbol names')
