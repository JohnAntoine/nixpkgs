{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "sipexer";
  version = "1.2.0";

  src = fetchFromGitHub {
    owner = "miconda";
    repo = "sipexer";
    rev = "v${version}";
    hash = "sha256-7L29nyFOc/5XAHpzGsFSngxMTwwIDkmwhIKIjHYGszc=";
  };

  vendorHash = "sha256-q2uNqKZc6Zye7YimPDrg40o68Fo4ux4fygjVjJdhqQU=";

  meta = with lib; {
    description = "Modern and flexible SIP CLI tool";
    homepage = "https://github.com/miconda/sipexer";
    changelog = "https://github.com/miconda/sipexer/releases/tag/v${version}";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ astro ];
    mainProgram = "sipexer";
  };
}
