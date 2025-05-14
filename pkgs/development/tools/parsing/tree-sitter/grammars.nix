{
  fetchFromGitHub,
}:

[
  {
    language = "bash";
    src = fetchFromGitHub {
      owner = "tree-sitter";
      repo = "tree-sitter-bash";
      rev = "487734f87fd87118028a65a4599352fa99c9cde8";
      hash = "sha256-7N1PLVMJxwN5FzHW9NbXZTzGhvziwLCC8tDO3qdjtOo=";
    };
  }
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
