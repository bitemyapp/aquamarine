#!/bin/bash
set -euo pipefail
[[ $# == 2 ]] || { echo "Usage: $0 original-package patched-package" >&2; exit 2; }
python3 - "$(dirname -- "$0")/NullConnectorRegression.cpp" "$1" "$2" <<'PY'
import os, pathlib, resource, shlex, subprocess, sys, tempfile
resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
source, original, patched = map(lambda p: str(pathlib.Path(p).resolve()), sys.argv[1:])
with tempfile.TemporaryDirectory(prefix='aquamarine-regression-') as tmp:
    root = pathlib.Path(tmp)
    for label, package in [('original', original), ('patched', patched)]:
        (root / label).mkdir()
        subprocess.run(['bsdtar', '-xf', package, '-C', str(root / label), 'usr/lib', 'usr/include'], check=True)
    fixed = root / 'patched/usr'
    flags = shlex.split(subprocess.check_output(['pkg-config', '--cflags', '--libs', 'aquamarine', 'pixman-1', 'libdrm'], text=True))
    binary = str(root / 'regression')
    subprocess.run(['g++', '-std=c++23', '-fno-access-control', source, '-I'+str(fixed/'include'), '-L'+str(fixed/'lib'), *flags, '-o', binary], check=True)
    for label, expected in [('original', -11), ('patched', 0)]:
        code = subprocess.run([binary], env={**os.environ, 'LD_LIBRARY_PATH': str(root/label/'usr/lib')}).returncode
        print(f'{label}: exit {code}, expected {expected}')
        assert code == expected, f'{label} regression failed'
PY
