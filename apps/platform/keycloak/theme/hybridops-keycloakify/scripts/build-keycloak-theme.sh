#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLS_DIR="${TOOLS_DIR:-$HOME/.local/tools}"
JDK_DIR="${TOOLS_DIR}/jdk-21"
MAVEN_DIR="${TOOLS_DIR}/apache-maven-3.9.9"

ensure_local_toolchain() {
  mkdir -p "${TOOLS_DIR}"

  if [[ ! -x "${JDK_DIR}/bin/java" ]]; then
    curl -fsSL "https://api.adoptium.net/v3/binary/latest/21/ga/linux/x64/jdk/hotspot/normal/eclipse?project=jdk" -o /tmp/hyops-jdk21.tar.gz
    mkdir -p "${JDK_DIR}"
    tar -xzf /tmp/hyops-jdk21.tar.gz -C "${JDK_DIR}" --strip-components=1
  fi

  if [[ ! -x "${MAVEN_DIR}/bin/mvn" ]]; then
    curl -fsSL "https://archive.apache.org/dist/maven/maven-3/3.9.9/binaries/apache-maven-3.9.9-bin.tar.gz" -o /tmp/hyops-maven.tar.gz
    tar -xzf /tmp/hyops-maven.tar.gz -C "${TOOLS_DIR}"
  fi
}

if ! command -v java >/dev/null 2>&1 || ! command -v mvn >/dev/null 2>&1; then
  if [[ "${AUTO_INSTALL_TOOLCHAIN:-1}" != "1" ]]; then
    echo "java and mvn are required; set AUTO_INSTALL_TOOLCHAIN=1 to install local copies automatically." >&2
    exit 1
  fi
  ensure_local_toolchain
  export JAVA_HOME="${JDK_DIR}"
  export PATH="${JAVA_HOME}/bin:${MAVEN_DIR}/bin:${PATH}"
fi

cd "${ROOT_DIR}"
npm install
npm run update-kc-gen
npm run build-keycloak-theme

echo ""
echo "Built theme jar:"
echo "  ${ROOT_DIR}/dist_keycloak/hybridops-theme.jar"
