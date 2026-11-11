{
  stdenv,
  makeWrapper,
  rclone,
  rsync,
  openssh,
  coreutils,
  ...
}:
stdenv.mkDerivation {
  pname = "fluxr";
  version = "0.1.0";
  src = ../src;
  buildInputs = [rclone rsync openssh coreutils];
  nativeBuildInputs = [makeWrapper];
  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/docs

    install $src/docs/help.txt $out/docs/help.txt
    install $src/bin/fluxr.sh $out/bin/fluxr
    wrapProgram $out/bin/fluxr \
    --prefix PATH $out/bin
  '';

  meta = {
    homepage = "https://github.com/niridium/fluxr-backup";
    description = "Tool to make backups between multiple hosts";
    # license = licenses.unspecified;
  };
}
