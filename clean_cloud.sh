#!/usr/bin/env bash
# Wrapper di compatibilità per il microkernel
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/brain.sh" clean
