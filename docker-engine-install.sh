#!/usr/bin/env bash
#
#     ____           __        ____   ____             __
#    /  _/___  _____/ /_____ _/ / /  / __ \____  _____/ /_____  _____
#    / // __ \/ ___/ __/ __ `/ / /  / / / / __ \/ ___/ //_/ _ \/ ___/
#  _/ // / / (__  ) /_/ /_/ / / /  / /_/ / /_/ / /__/ ,< /  __/ /
# /___/_/ /_/____/\__/\__,_/_/_/  /_____/\____/\___/_/|_|\___/_/
#
#     ______            _
#    / ____/___  ____ _(_)___  ___
#   / __/ / __ \/ __ `/ / __ \/ _ \
#  / /___/ / / / /_/ / / / / /  __/
# /_____/_/ /_/\__, /_/_/ /_/\___/
#             /____/
#
# SOURCES:
#   + https://docs.docker.com/engine/install/ubuntu/
#   + https://docs.docker.com/engine/install/debian/
#
# IMPORTANT NOTE:
#   + Distro maintainers provide unofficial distributions of Docker packages in APT.
#   + This script is written for debian/linux mint/ubuntu

export DEBIAN_FRONTEND=noninteractive
set -euo pipefail

step() {
  printf '[%d/5] %s\n' "$1" "$2"
}

check_user(){
  if [[ "${EUID}" -eq 0 ]];then
    echo "Don't run this script as root. Run it as a normal user; it uses sudo internally."
    exit 1
  fi
}

uninstall_old_docker() {
  # uninstall all conflicting packages:
  # You have to delete any edited configuration files manually.
  for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
    sudo apt-get -yq remove "$pkg" > /dev/null || true
  done

  # Uninstall the Docker Engine, CLI, containerd, and Docker Compose packages:
  # useful if you had older docker installs
  for pkg in docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras; do
    sudo apt-get -yq purge "$pkg" > /dev/null || true
  done

  # delete all images, containers, and volumes (for a clean install)
  # (if you care about your images you must host them to docker hub)
  sudo rm -rf /var/lib/docker
  sudo rm -rf /var/lib/containerd

  # Remove source list and keyrings
  sudo rm -f /etc/apt/sources.list.d/docker.list
  sudo rm -f /etc/apt/sources.list.d/docker.sources
  sudo rm -f /etc/apt/keyrings/docker.asc

  # Remove daemon configs (if present)
  sudo rm -f /etc/docker/daemon.json       # regular setup
  sudo rm -f ~/.config/docker/daemon.json  # rootless mode

  # You have to delete any edited configuration files manually.
  # rm -r $HOME/.docker
}


add_docker_apt() {
  sudo apt-get -yq update > /dev/null
  sudo apt-get -yq install --no-install-recommends ca-certificates curl > /dev/null
  sudo install -m 0755 -d /etc/apt/keyrings

  # shellcheck source=/dev/null
  . /etc/os-release

  case "${ID,,}" in
    linuxmint|ubuntu)
      OS="ubuntu"
      SUITE="${UBUNTU_CODENAME:?UBUNTU_CODENAME missing in /etc/os-release}"
      echo "Detected: ${PRETTY_NAME:-$ID}: using Docker repo linux/${OS} suite ${SUITE}"
      ##  Add Docker's official GPG key:
      sudo curl -fsSL "https://download.docker.com/linux/${OS}/gpg" -o /etc/apt/keyrings/docker.asc
      sudo chmod a+r /etc/apt/keyrings/docker.asc

      echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${OS} $SUITE stable" | \
        sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
      ;;
    debian)
      OS="debian"
      SUITE="${VERSION_CODENAME:?VERSION_CODENAME missing in /etc/os-release}"
      echo "Detected: ${PRETTY_NAME:-$ID}: using Docker repo linux/${OS} suite ${SUITE}"
      #  Add Docker's official GPG key:
      sudo curl -fsSL "https://download.docker.com/linux/${OS}/gpg" -o /etc/apt/keyrings/docker.asc
      sudo chmod a+r /etc/apt/keyrings/docker.asc
      # https://wiki.debian.org/SourcesList
      sudo tee /etc/apt/sources.list.d/docker.sources <<EOF
Types: deb
URIs: https://download.docker.com/linux/debian
Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF
      ;;
    *)
      echo "Unsupported distro: ${PRETTY_NAME:-$ID}"
      exit 1
      ;;
  esac


  sudo apt-get -yq update > /dev/null

}

install_docker() {
  # Install the Docker packages (latest version)
  sudo apt-get -yq install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  docker --version || true
  docker compose version || true

  # # the docker service runs automatically after installation
  # sudo systemctl status docker
  # # if not start it manually
  # sudo systemctl start docker

  # Verify that the Docker Engine installation is successful by running the hello-world image.
  # sudo docker run hello-world
}

postinstall() {
  # allow non-privileged users to run Docker commands

  # Create the docker group (if does not exist)
  getent group docker >/dev/null || sudo groupadd docker
  # Add your user to the docker group.
  sudo usermod -aG docker "$USER"
  # activate the changes to groups OR Log out and log back in so that your group membership is re-evaluated.
  # newgrp docker

  echo "Log out and log back in so your 'docker' group membership takes effect"

  ## Configure Docker to start on boot with systemd
  sudo systemctl enable --now docker.service
  sudo systemctl enable --now containerd.service

  #  To stop this behavior, use disable instead.
  #  sudo systemctl disable docker.service
  #  sudo systemctl disable containerd.service
}

if check_user; then
  step "1" "check user OK"
fi

if uninstall_old_docker;then
  step "2" "uninstall old docker OK"
fi

if add_docker_apt; then
  step "3" "add docker's apt OK"
fi

if install_docker; then
  step "4" "install docker OK"
fi

if postinstall; then
  step "5" "post install OK"
fi
