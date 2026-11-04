# THIRD_PARTY_NOTICES.md

> SPDX-License-Identifier: Apache-2.0
>
> Open-source license disclosure per preferences.md §29: this file records the licenses of third-party code and data that ships with, links against, or is embedded in this project.

## Current state

- **This project's code and files:** Apache License 2.0 (see `LICENSE`).

## Runtime dependencies

None. The library is self-contained: the Alire crate declares no external dependencies, and the core is pure SPARK over bounded arithmetic (no heap, no I/O, no OS calls). The `tests/` crate depends only on this repository's own `adrc_ada` crate through a local path pin.

## Toolchain and CI (not shipped)

The following tools build, verify, or gate this project but are not part of any artifact it distributes: GNAT and gnatprove (FSF builds via Alire), Alire itself, and the pre-commit hook tools (Gitleaks, cspell, Vale, OpenGrep). Their licenses govern their own distributions, not this project's output.

## In-app disclosure

Not applicable: ADRC-in-Ada is a linkable library with no distributable end-user application surface; downstream applications embed this library and carry their own disclosure.
