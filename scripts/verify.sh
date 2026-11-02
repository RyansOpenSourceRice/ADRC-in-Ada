#!/usr/bin/env bash
# SPDX-License-Identifier: Apache-2.0
#
# Local verification gate: build library + examples, prove the SPARK
# core, run the test crate. Run before every push; CI mirrors the same
# steps (preferences §9: the local command is the source of truth).
set -euo pipefail
cd "$(dirname "$0")/.."

echo "=== build library + examples ==="
alr build
alr exec -- gnat make -q -P examples.gpr

echo "=== gnatprove (SPARK Silver: absence of runtime errors) ==="
gnatprove -P proof/spark_core.gpr -U -j4 --level=3 --timeout=120

echo "=== tests ==="
( cd tests && alr build && alr run -s )

echo "verify: OK"
