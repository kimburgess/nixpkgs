{
  fetchFromGitHub,
}:

[
  rec {
    language = "netlinx";
    version = "1.0.3";
    src = fetchFromGitHub {
      owner = "Norgate-AV";
      repo = "tree-sitter-netlinx";
      rev = "v${version}";
      hash = "sha256-ZG3zeE/6FYb+D9WrTNocXjbNJr3re7ajmaanBlSgfo4=";
    };
  }
]

# TODO: check if details above can be condensed
# this requires "src" and "version" attrs to remain accurate for line num

# {
#   tree-sitter-netlinx = {
#     language = "netlinx";
#     version = "1.0.3";
#     src = fetchFromGitHub {
#       owner = "Norgate-AV";
#       repo = "tree-sitter-netlinx";
#       rev = "6d3c01e54d150c6d3dcf99cad95a1f5fa0293018";
#       hash = "sha256-ZG3zeE/6FYb+D9WrTNocXjbNJr3re7ajmaanBlSgfo4=";
#     };
#   };
# }

# [
#   {
#     language = "bash";
#     src = fetchFromGitHub {
#       owner = "tree-sitter";
#       repo = "tree-sitter-bash";
#       rev = "487734f87fd87118028a65a4599352fa99c9cde8";
#       hash = "sha256-7N1PLVMJxwN5FzHW9NbXZTzGhvziwLCC8tDO3qdjtOo=";
#     };
#   }
#   {
#     language = "comment";
#     src = fetchFromGitHub {
#       owner = "stsewd";
#       repo = "tree-sitter-comment";
#       rev = "ef429992748f89e176243411e94b8ffc8777d118";
#       hash = "sha256-XfHUHWenRjjQer9N4jhkFjNDlvz8ZI8Qep5eiWIyr7Q=";
#     };
#   }
#   {
#     language = "netlinx";
#     version = "1.0.3";
#     src = fetchFromGitHub {
#       owner = "Norgate-AV";
#       repo = "tree-sitter-netlinx";
#       rev = "6d3c01e54d150c6d3dcf99cad95a1f5fa0293018";
#       hash = "sha256-ZG3zeE/6FYb+D9WrTNocXjbNJr3re7ajmaanBlSgfo4=";
#     };
#   }
#   {
#     language = "tsx";
#     src = fetchFromGitHub {
#       owner = "tree-sitter";
#       repo = "tree-sitter-typescript";
#       rev = "f975a621f4e7f532fe322e13c4f79495e0a7b2e7";
#       hash = "sha256-CU55+YoFJb6zWbJnbd38B7iEGkhukSVpBN7sli6GkGY=";
#     };
#   }
#   {
#     language = "typescript";
#     src = fetchFromGitHub {
#       owner = "tree-sitter";
#       repo = "tree-sitter-typescript";
#       rev = "f975a621f4e7f532fe322e13c4f79495e0a7b2e7";
#       hash = "sha256-CU55+YoFJb6zWbJnbd38B7iEGkhukSVpBN7sli6GkGY=";
#     };
#   }
# ]
