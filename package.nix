{
  stdenv,
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "infrared";
  version = "2.0.0-alpha.r2";

  src = fetchFromGitHub {
    owner = "haveachin";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-dbAwOpRSDzcHtOO34FxKWLyNEEJUIvsSuysdUcu5Y9w=";
  };

  vendorHash = "sha256-CxMYSRG9yPY6zJyvmpVGz3VkL1trAd1Qg/RLRl3scAY=";
  
  doCheck = false;

  meta = with lib; {
    description = "A Minecraft Reverse Proxy";
    homepage = "https://github.com/haveachin/${pname}";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}
