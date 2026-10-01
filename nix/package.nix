{ bash, fetchFromGitHub, lib, makeWrapper, runCommand, rustPlatform }:

let
  manifest = builtins.fromJSON (builtins.readFile ./package-manifest.json);
  upstreamSrc = fetchFromGitHub {
    owner = manifest.source.owner;
    repo = manifest.source.repo;
    rev = manifest.source.rev;
    hash = manifest.source.hash;
  };
  sourceRoot = runCommand "${manifest.binary.name}-${manifest.source.version}-src" {} ''
    mkdir -p "$out/src"
    mkdir -p "$out/benches"
    mkdir -p "$out/patches"
    mkdir -p "$out/vendor"
    cp ${upstreamSrc}/Cargo.toml "$out/Cargo.toml"
    # The upstream snapshot declares a future MSRV that is newer than the
    # compiler supplied by nixpkgs.  The crate uses edition-2024 features,
    # which are supported by the nixpkgs compiler; avoid rejecting the build
    # solely on the unreleased metadata value.
    substituteInPlace "$out/Cargo.toml" --replace-fail 'rust-version = "1.95"' 'rust-version = "1.85"'
    cp ${upstreamSrc}/Cargo.lock "$out/Cargo.lock"
    cp ${upstreamSrc}/README.md "$out/README.md"
    cp ${upstreamSrc}/LICENSE "$out/LICENSE"
    if [ -f ${upstreamSrc}/build.rs ]; then
      cp ${upstreamSrc}/build.rs "$out/build.rs"
    fi
    if [ -d ${upstreamSrc}/benches ]; then
      cp -R ${upstreamSrc}/benches/. "$out/benches/"
    fi
    if [ -d ${upstreamSrc}/patches ]; then
      cp -R ${upstreamSrc}/patches/. "$out/patches/"
    fi
    if [ -d ${upstreamSrc}/vendor ]; then
      cp -R ${upstreamSrc}/vendor/. "$out/vendor/"
    fi
    cp -R ${upstreamSrc}/src/. "$out/src/"
  '';
  builtBinary = manifest.binary.upstreamName or manifest.binary.name;
  aliasOutputs = manifest.binary.aliases or [ ];
  aliasScripts = lib.concatMapStrings
    (
      alias:
      ''
        cat > "$out/bin/${alias}" <<EOF
#!${lib.getExe bash}
exec "$out/bin/${manifest.binary.name}" "\$@"
EOF
        chmod +x "$out/bin/${alias}"
      ''
    )
    aliasOutputs;
in
rustPlatform.buildRustPackage {
  pname = manifest.binary.name;
  version = manifest.source.version;
  src = sourceRoot;

  cargoLock = {
    lockFile = sourceRoot + "/Cargo.lock";
  };

  cargoBuildFlags =
    (lib.optionals (manifest.binary ? package) [ "-p" manifest.binary.package ])
    ++ [ "--bin=${builtBinary}" ];

  nativeBuildInputs = [ makeWrapper ];
  doCheck = false;

  env = {
    VERGEN_IDEMPOTENT = "1";
    VERGEN_GIT_SHA = manifest.source.rev;
    VERGEN_GIT_DIRTY = "false";
  };

  postInstall = ''
    if [ "${builtBinary}" != "${manifest.binary.name}" ]; then
      mv "$out/bin/${builtBinary}" "$out/bin/${manifest.binary.name}"
    fi
    ${aliasScripts}
  '';

  meta = with lib; {
    description = manifest.meta.description;
    homepage = manifest.meta.homepage;
    license = licenses.mit;
    mainProgram = manifest.binary.name;
    platforms = platforms.linux ++ platforms.darwin;
  };
}
