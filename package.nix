{
  stdenv,
  makeWrapper,
  rsync,
  openssh,
  coreutils,
  ...
}:
stdenv.mkDerivation {
  pname = "fluxr";
  version = "0.1.0";
  src = ./src;
  buildInputs = [rsync openssh coreutils];
  nativeBuildInputs = [makeWrapper];
  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/bin/modules
    mkdir -p $out/bin/integrations

    install $src/fluxr.sh $out/bin/fluxr
    wrapProgram $out/bin/fluxr \
    --prefix PATH $out/bin

    install $src/modules/propagation.sh $out/bin/modules/propagation
    install $src/integrations/postgres.sh $out/bin/integrations/postgres
  '';

  meta = {
    homepage = "https://github.com/niridium/fluxr-backup";
    description = "Tool to make backups between multiple hosts";
    # license = licenses.unspecified;
  };
}
