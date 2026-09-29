# Aquamarine 0.15.0 teardown-crash backport

This directory preserves the recipe for the locally installed
`aquamarine 0.15.0-2.1` package. It is based on
[Arch's 0.15.0-2 recipe](https://gitlab.archlinux.org/archlinux/packaging/packages/aquamarine/-/blob/0.15.0-2/PKGBUILD),
with one upstream source fix, a local package-release suffix, and the three
non-graphical upstream tests enabled. This is a personal backport, not an
official Arch or Omarchy package.

## Source and provenance

- Base: upstream `v0.15.0`, commit `783bfd9ae441d1d0519b979ac68b73ddd6e81df0`.
- Fix: Vaxry's upstream commit
  [`fc77bd58a2c9ef6d0760a7c9c3b7b6670f956f28`](https://github.com/hyprwm/aquamarine/commit/fc77bd58a2c9ef6d0760a7c9c3b7b6670f956f28).
- Backport: commit
  [`23f24c911a5d76b8dea03820cd37150b1ff226fe`](https://github.com/bitemyapp/aquamarine/commit/23f24c911a5d76b8dea03820cd37150b1ff226fe)
  on this repository's `fix-null-connector-logout` branch. The cherry-pick
  preserves the original author and upstream commit reference.
- The recipe downloads the versioned upstream tarball and applies the included
  `fix-null-connector.patch`; both inputs have SHA-256 checksums in `PKGBUILD`.
  It does not build a moving branch.

During DRM backend teardown, a connector entry can already be null while the
remaining connectors are being disconnected. `flushAsyncCommitEvents()` used
to dereference every entry. This patch checks the connector before accessing
its output. The library source differs from v0.15.0 by this one-line guard.

The separate [Omarchy PR #13778](https://github.com/omacom/omarchy/pull/13778)
preserves docked lid policy across logout and DPMS. That policy fix and this
compositor-crash fix address separate parts of the observed logout failure.

## Build

On an Arch build environment with `base-devel` and the dependencies listed in
`PKGBUILD` installed, run from this directory:

```sh
makepkg --verifysource
makepkg --cleanbuild
```

The recipe runs upstream's `attachments`, `output`, and `commitThread` tests.
It produces a package without installing it. Build against dependencies
compatible with the target system; this v0.15.0 recipe is intended for the
Omarchy stable package set on which it was tested.

## Regression test

The standalone test constructs a synthetic connector list containing a null
entry and calls the real library. It does not open a GPU or alter the desktop.
Core dumps are disabled for the expected failure. It uses
`-fno-access-control` to reach the internal teardown method without modifying
the library.

With `g++`, Python 3, `pkg-config`, `bsdtar`, and the matching Aquamarine
development/runtime dependencies available, pass the original and patched
package files:

```sh
./test-regression.sh \
  /path/to/aquamarine-0.15.0-2-x86_64.pkg.tar.zst \
  /path/to/aquamarine-0.15.0-2.1-x86_64.pkg.tar.zst
```

Verified on September 29, 2026:

```text
original: exit -11, expected -11
patched: exit 0, expected 0
```

The original package segfaults; the patched package returns successfully.
All three upstream test suites named above also passed.

SHA-256 of the installed package artifact:

```text
af56f724f02dc0f6f932fcf9f3c5430a61a584e10fd2ee70f2292f969479b333  aquamarine-0.15.0-2.1-x86_64.pkg.tar.zst
```

The binary is not committed here, and rebuilding with a different toolchain
may produce a different artifact hash.

## Updates

As of September 29, 2026, upstream v0.15.1 also lacks this fix: the fix was
committed after that release. A higher package version can supersede this
backport without containing the guard. Retire the backport only after checking
that the incoming official package includes the upstream fix or an equivalent
change. No package pin or automatic update hook is installed by this recipe.
