{
  fetchFromGitHub,
}:

[
  {
    language = "netlinx";
    src = fetchFromGitHub {
      owner = "Norgate-AV";
      repo = "tree-sitter-netlinx";
      rev = "v1.0.3";
      hash = "sha256-ZG3zeE/6FYb+D9WrTNocXjbNJr3re7ajmaanBlSgfo4=";
    };
  }
]
