{
  pkgs ? import <nixpkgs> { },
}:
with pkgs;
mkShell rec {
  name = "helm";
  packages = with pkgs; [ bashInteractive ];
  buildInputs = [
    aspell
    curl
    dig
    cfssl
    k9s
    git
    kubectl
    kind
    (pkgs.wrapHelm pkgs.kubernetes-helm { plugins = [ pkgs.kubernetes-helmPlugins.helm-secrets ]; })
    # https://github.com/komodorio/helm-dashboard
    #(pkgs.wrapHelm pkgs.kubernetes-helm { plugins = [ pkgs.kubernetes-helmPlugins.helm-dashboard ]; })

    kustomize
    jq
    openssh
    ripgrep
    act
    minikube
    nerdctl
    openldap
    ripgrep
    shelldap
    stern
    shellcheck
    lsof
  ];
  shellHook =
    let
      icon = "f121";
    in
    ''
      export PS1="$(echo -e '\u${icon}') {\[$(tput sgr0)\]\[\033[38;5;228m\]\w\[$(tput sgr0)\]\[\033[38;5;15m\]} (${name}) \\$ \[$(tput sgr0)\]"
      alias gitc="git -c user.email=gburd@symas.com commit --gpg-sign=1FC1E7793410DE46 ."
    '';
}
