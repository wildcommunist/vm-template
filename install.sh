#!/usr/bin/env bash
set -e

# Write content to console
console() {
  CURR_TIME=$(date +"%Y-%m-%d %T")
  MSG=${1}
  MSG_TYPE=${2,,:=""}
  C_MSG_DT="[${BGreen}${CURR_TIME}${RESET}]"
  C_MSG=""
  if [ "${SHOW_DEBUG}" = "true" ]; then
    if [ "${MSG_TYPE}" = "debug" ]; then
      C_MSG="${C_MSG} [${BCyan}DEBUG${RESET}] ${MSG}"
    fi
  fi

  case "${MSG_TYPE}" in
  "warn")
    C_MSG="${C_MSG} [${BYellow}WARN${RESET}] ${MSG}"
    ;;
  "err")
    C_MSG="${C_MSG} [${BRed}ERROR${RESET}] ${MSG}"
    ;;
  "")
    C_MSG="${C_MSG} ${MSG}"
    ;;
  esac
  if [ -z "${C_MSG}" ]; then
    return
  fi
  echo -e "${C_MSG_DT}${C_MSG}"
}

docker_install() {
  console "Installing docker"
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  sudo apt-get update
  sudo apt-get install docker-ce docker-ce-cli containerd.io -y
  docker version

  sudo usermod -aG docker ${USER}
  sudo systemctl enable docker --now
  console "Docker installed"
}

compose_install() {
  console "Installing docker compose"
  mkdir -p ~/.docker/cli-plugins/
  VER=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
  curl -L "https://github.com/docker/compose/releases/download/"$VER"/docker-compose-$(uname -s)-$(uname -m)" -o ~/.docker/cli-plugins/docker-compose
  chmod +x ~/.docker/cli-plugins/docker-compose
  docker compose version
  console "Docker compose installed"
}

nvm_install() {
  console "Installing node version manager and PM2"
  sudo apt install curl -y
  curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | bash
  source ~/.bashrc
  nvm install --lts
  npm install -g pm2

  pm2 install pm2-logrotate
  pm2 set pm2-logrotate:retain 5
  pm2 set pm2-logrotate:max_size 100M
  console "Installed nvm, node and pm2"
}

python_install() {
  console "Installing python3.10"
  sudo apt install python3.10-venv -y
  sudo apt install python-is-python3 -y
  curl https://bootstrap.pypa.io/get-pip.py | python
}

common() {
  console "Installing common packages..."
  sudo apt install jq mc nano git curl net-tools inetutils-ping dnsutils htop nano -y
}

start() {
  common
  docker_install
  compose_install
  python_install
  nvm_install
}

start
