rand_password() {
  echo "$(date +%s | sha256sum | base64 | head -c 32 | sha256sum | awk '{print $1}')"
}

export REMOTE_USER="${REMOTE_USER:-git}"
export REMOTE_PASS="${REMOTE_PASS:-$(rand_password)}"
export REMOTE_ROOT_USER="${REMOTE_ROOT_USER:-"root"}"
export REMOTE_PORT="${REMOTE_PORT:-"22"}"
export HOST_DOMAIN="${HOST_DOMAIN}"

export AZK_DOMAIN="${AZK_DOMAIN:-"dev.azk.io"}"
export AZK_AGENT_START_COMMAND="${AZK_AGENT_START_COMMAND:-"azk agent start"}"
export AZK_RESTART_COMMAND="${AZK_RESTART_COMMAND:-"azk restart -R"}"
export AZK_AGENT_LOG_FILE="${AZK_AGENT_LOG_FILE:-"/tmp/azk-agent.log"}"

export GIT_REF="${GIT_REF:-"master"}"
export GIT_REMOTE="${GIT_REMOTE:-"azk_deploy"}"

export PROJECTS_PATH="${PROJECTS_PATH:-"/home/${REMOTE_USER}"}"

export ENV_FILE="${ENV_FILE:-".env"}"
