#!/bin/bash
# Setup SASL module symlinks before starting postfix
for f in /usr/lib/x86_64-linux-gnu/sasl2/lib*.so.2.0.25; do
    name=$(basename "$f" .2.0.25)
    ln -sf "$f" "/usr/lib/sasl2/$name" 2>/dev/null
done
# Run the original postfix.sh
exec /postfix.sh
