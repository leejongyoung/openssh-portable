#!/bin/sh
# Verify .github/pin_actions.sh under a strict POSIX shell (BusyBox ash in Docker,
# no network, read-only root): (1) syntax check, (2) a fixture run with a stubbed
# `git` that proves the here-string replacement still resolves action@ref -> hash.
set -eu
here=$(cd "$(dirname "$0")" && pwd)
img=busybox:1.36
docker run --rm --network none --read-only -v "$here/pin_actions.sh:/probe.sh:ro" \
    "$img" sh -n /probe.sh
echo "pin_actions.sh: POSIX sh syntax OK"

docker run --rm --network none -v "$here/pin_actions.sh:/probe.sh:ro" "$img" sh -c '
set -eu
mkdir -p /w/workflows /tmp/actions/checkout
cd /w
printf "jobs:\n  a:\n    steps:\n      - uses: actions/checkout@v4\n" > workflows/t.yml
printf "#!/bin/sh\necho 0123456789abcdef0123456789abcdef01234567\n" > /bin/git
chmod +x /bin/git
sh /probe.sh >/dev/null
grep -q "uses: actions/checkout@0123456789abcdef0123456789abcdef01234567 # v4" workflows/t.yml
'
echo "pin_actions.sh: fixture pin OK"
