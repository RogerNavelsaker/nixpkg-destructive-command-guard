{ bash, lib, makeWrapper, rustPlatform }:

let
  manifest = builtins.fromJSON (builtins.readFile ./package-manifest.json);
  sourceRoot = lib.cleanSource ../upstream;
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
  version = manifest.package.version;
  src = sourceRoot;

  cargoLock = {
    lockFile = ../upstream/Cargo.lock;
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
