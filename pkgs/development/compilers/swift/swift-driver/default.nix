{
  lib,
  stdenv,
  callPackage,
  fetchpatch,
  swift,
  swiftpm,
  swiftpm2nix,
  Foundation,
  XCTest,
  sqlite,
  ncurses,
  replaceVars,
}:
let
  sources = callPackage ../sources.nix { };
  generated = swiftpm2nix.helpers ./generated;

  # On Darwin, we only want ncurses in the linker search path, because headers
  # are part of libsystem. Adding its headers to the search path causes strange
  # mixing and errors.
  # TODO: Find a better way to prevent this conflict.
  ncursesInput = if stdenv.hostPlatform.isDarwin then ncurses.out else ncurses;
in
stdenv.mkDerivation {
  pname = "swift-driver";

  inherit (sources) version;
  src = sources.swift-driver;

  nativeBuildInputs = [
    swift
    swiftpm
  ];
  buildInputs = [
    Foundation
    XCTest
    sqlite
    ncursesInput
  ];

  patches = [
    ./patches/nix-resource-root.patch
    ./patches/disable-catalyst.patch
    ./patches/linux-fix-linking.patch
    # TODO: Replace with branch patch once merged:
    # https://github.com/apple/swift-driver/pull/1197
    (fetchpatch {
      url = "https://github.com/apple/swift-driver/commit/d3ef9cdf4871a58eddec7ff0e28fe611130da3f9.patch";
      hash = "sha256-eVBaKN6uzj48ZnHtwGV0k5ChKjak1tDCyE+wTdyGq2c=";
    })
    # Prevent a warning about SDK directories we don't have.
    (replaceVars ./patches/prevent-sdk-dirs-warnings.patch {
      inherit (builtins) storeDir;
    })
  ];

  configurePhase = generated.configure + ''
    swiftpmMakeMutable swift-tools-support-core
    patch -p1 -d .build/checkouts/swift-tools-support-core -i ${
      fetchpatch {
        url = "https://github.com/apple/swift-tools-support-core/commit/990afca47e75cce136d2f59e464577e68a164035.patch";
        hash = "sha256-PLzWsp+syiUBHhEFS8+WyUcSae5p0Lhk7SSRdNvfouE=";
        includes = [ "Sources/TSCBasic/FileSystem.swift" ];
      }
    }
  '';

  # TODO: Tests depend on indexstore-db being provided by an existing Swift
  # toolchain. (ie. looks for `../lib/libIndexStore.so` relative to swiftc.
  #doCheck = true;

  # TODO: Darwin-specific installation includes more, but not sure why.
  installPhase = ''
    binPath="$(swiftpmBinPath)"
    mkdir -p $out/bin
    for executable in swift-driver swift-help swift-build-sdk-interfaces; do
      cp $binPath/$executable $out/bin/
    done
  '';

  meta = {
    description = "Swift compiler driver";
    homepage = "https://github.com/apple/swift-driver";
    platforms = with lib.platforms; linux ++ darwin;
    license = lib.licenses.asl20;
    teams = [ lib.teams.swift ];
  };
}
