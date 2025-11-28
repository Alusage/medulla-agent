#!/bin/bash
#
# Medulla Agent Installation Script for Zorin OS / Ubuntu 22.04
# Based on official Medulla installer with Zorin OS support
# Version: 1.0
#

set -e

BASE_URL="http://medulla.97.alusage.fr/downloads"
INVENTORY_TAG=""
AGENT_VERSION="5.4.3"
PULSE_AGENT_FILENAME="pulse-xmpp-agent-5.4.3.tar.gz"
AGENT_PLUGINS_FILENAME="pulse-machine-plugins-5.4.3.tar.gz"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [ "$(id -u)" != "0" ]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

detect_distro() {
    if [ ! -e /etc/os-release ]; then
        log_error "Cannot detect operating system"
        exit 1
    fi

    . /etc/os-release

    # Handle Zorin OS with native repositories
    if [ "$ID" = "zorin" ]; then
        log_info "Detected $PRETTY_NAME"
        DISTRO="zorin"
        VERSION=$VERSION_ID

        if [ "$VERSION_ID" = "17" ]; then
            log_info "Using Zorin OS 17 native repository"
        elif [ "$VERSION_ID" = "18" ]; then
            log_info "Using Zorin OS 18 native repository"
        else
            log_warn "Unknown Zorin version $VERSION_ID"
            log_warn "Falling back to Debian 12 repository"
            DISTRO="debian"
            VERSION="12"
        fi
    # Handle Ubuntu (use Debian repository as fallback)
    elif [ "$ID" = "ubuntu" ]; then
        log_info "Detected $PRETTY_NAME"
        DISTRO="debian"
        if [ "$VERSION_ID" = "22.04" ]; then
            VERSION="12"
            log_info "Using Debian 12 (bookworm) repository"
        elif [ "$VERSION_ID" = "20.04" ]; then
            VERSION="11"
            log_info "Using Debian 11 (bullseye) repository"
        else
            log_warn "Unknown Ubuntu version $VERSION_ID, trying Debian 12"
            VERSION="12"
        fi
    # Handle native Debian
    else
        DISTRO=$ID
        VERSION=$VERSION_ID
    fi

    log_info "Detected OS: $PRETTY_NAME"
    log_info "Using repository: $DISTRO/$VERSION"

    case "$DISTRO" in
        mageia|debian|zorin)
            ;;
        *)
            log_error "Distribution $DISTRO is not supported"
            exit 1
            ;;
    esac
}

install_root_ca() {
    log_info "Installing Medulla Root CA certificate..."

    mkdir -p /usr/local/share/ca-certificates

    # Download Root CA from server
    wget -q "${BASE_URL}/../pki/ca-chain.cert.pem" -O /tmp/medulla-ca-chain.pem || {
        log_warn "Could not download CA from server, using embedded certificate"
        # Fallback to embedded certificate
        cat > /usr/local/share/ca-certificates/medulla-root-ca.crt << 'EOF'
-----BEGIN CERTIFICATE-----
MIIFTDCCAzSgAwIBAgIUNeVFpUpQEnGtT0Lw48VwGYhUq4AwDQYJKoZIhvcNAQEL
BQAwNTELMAkGA1UEBhMCRlIxEDAOBgNVBAoMB01lZHVsbGExFDASBgNVBAMMC1B1
bHNlUm9vdENBMB4XDTI1MTEyNzA1Mjc1NFoXDTM1MTEyNTA1Mjc1NFowNTELMAkG
A1UEBhMCRlIxEDAOBgNVBAoMB01lZHVsbGExFDASBgNVBAMMC1B1bHNlUm9vdENB
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAhEXwIM6iEQMyObRhqAne
mXPsywvslcffE5J8SYeJ3WZCFUsSwoz1PLF604G0nLe3ahaxikyDR41wmGtu/vaF
ArwwNaPYSXdeqLjl3LvScygWeqyEfHvzAUpS5Xxf8iVTEH0jVt+UtNA9nD+gDXTO
1kJsrg/sbEEgiqMQn4gqmJvz0m/EBzg+I3bJxYxuaULOpyxI+2AmuOMMsfWy6Fvs
cMoPesino4EEGnsqgT94GOX80EtE60zCeRxIZ7VhNFJzOcGcB6eE6hDjWzMe+eMP
qnOhltKkB1suM4r3rBvOlWksC832jkgTntNbDaU1sPOh0avGA982GyUKu/X085D7
3lbF2gHmM5h7Br/2JxuPNkfnEsNLVY74WYWfAMwUeaiQKf4MM2SgyfEpja3jcR49
jPaDZmDCUf5E8olMKAhT559HO6NlZsZO7ZCMwJ3zd66pVUj3sD62da0kCmk4465H
s9vBr+o/TjQhgGQJ9vnS3HDnWvfApdqnld558BVQqRinjh0RRWG9cf9dEcWbjwL3
R/+dEuwIrMp2e8XHHzj89k7Mqu3NtTCI/V5E3kmwKLWyHOh4OBN9WhM/jIKOdkNk
uNfv/IuGEPOlESomifGTa6DEYo7BZtiJRh0LfxGF/AXpKtAfcoF087Hu+agb4Wxk
TE70OkG1ENnKhjXObpRjLKsCAwEAAaNUMFIwFgYDVR0RBA8wDYILUHVsc2VSb290
Q0EwCwYDVR0PBAQDAgEGMAwGA1UdEwQFMAMBAf8wHQYDVR0OBBYEFPY2aF5rDU9g
7chcmT6BbHVT+SqtMA0GCSqGSIb3DQEBCwUAA4ICAQByNMsAIuFPn+cjmedT/r8z
zJSEfimlAvlnZuFuXGN119VZ1X9pwKqCO2utKjVy4kppaIXe2devpsCCPRzlHC/Z
v3nBNiLRef99wLJRZNBSpaWvBJQ5OiUw8+fHbUflj368K0VDC8cfq0zYyRi5tI7R
Toz1AKIfsyG94pRrOKrbn3uZu58hUmZh4/0+Qb8PhGhi9Cf4k40cv4MkDU0XHmbe
sDIuIsACoOeEwgghz42D8P2XnKZf98jtwkPrfLA3idOv+2CS3xvslehwXq+igqsB
1Ww/RXZbXTjwEq0DGvlsgbwfLO5QKb3hkNF6HAYxZZX/MCsRcSFw/P5fcxYzqq/+
ESQSY6lE382XQ8CWWTRINeL/O4ij4PIJPNGJsMl6l5ejTLfTNrkuZIWbHQiUeMTC
p6Djm63JNQChjze9LERKnMpaqFzvnAgspEIFVuKfvXeglujfTCbYB7oe4obl4SHO
1Ww1x/Lo0mALJG7x+NEtRSrFe+YY2stcKQenbZyY4ZZOAMfg2TpVusROb17z9g92
JgmZ7cWIJADZY1Ilk60NMg7cgNd6AcGzGI7gl6PKyK2DAIe1JneEmizKv6wbloIu
jJ3hyTnyA0MHLjnSANtnQ9cg3WoMvKqrXnv/z8XPA2TDCCXvRKud4rgc4NjAl5qY
jgoWj204U6JmQ6MaHgh6cw==
-----END CERTIFICATE-----
EOF
    }

    update-ca-certificates
    log_info "Root CA certificate installed"
}

configure_repo() {
    log_info "Configuring Medulla repository..."

    case "$DISTRO" in
        mageia)
            ;;
        debian|ubuntu|zorin)
            echo "deb [trusted=yes] ${BASE_URL}/lin/deb/${DISTRO}/${VERSION}/ ./" > /etc/apt/sources.list.d/pulseagent.list
            apt update -o Dir::Etc::sourcelist="sources.list.d/pulseagent.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0" || {
                log_error "Failed to update repository. Make sure ${BASE_URL}/lin/deb/${DISTRO}/${VERSION}/ exists"
                exit 1
            }
            ;;
        *)
            ;;
    esac
}

install_fusioninventory() {
    log_info "Installing FusionInventory Agent..."

    # Temporarily disable Medulla repository
    if [ -f /etc/apt/sources.list.d/pulseagent.list ]; then
        log_warn "Temporarily disabling Medulla repository"
        mv /etc/apt/sources.list.d/pulseagent.list /etc/apt/sources.list.d/pulseagent.list.disabled
    fi

    apt-get update
    apt-get --fix-broken install -y

    DEBIAN_FRONTEND=noninteractive apt-get install -y fusioninventory-agent || {
        log_error "Failed to install fusioninventory-agent"
        [ -f /etc/apt/sources.list.d/pulseagent.list.disabled ] && \
            mv /etc/apt/sources.list.d/pulseagent.list.disabled /etc/apt/sources.list.d/pulseagent.list
        exit 1
    }

    # Restore Medulla repository
    if [ -f /etc/apt/sources.list.d/pulseagent.list.disabled ]; then
        mv /etc/apt/sources.list.d/pulseagent.list.disabled /etc/apt/sources.list.d/pulseagent.list
        apt-get update
    fi

    log_info "FusionInventory Agent installed: $(fusioninventory-agent --version | head -1)"
}

install_agent() {
    log_info "Installing Medulla Agent..."

    case "$DISTRO" in
        mageia)
            ;;
        debian|zorin)
            # For Debian 11, 12, Zorin OS and Ubuntu derivatives
            # First install packages available in all versions
            apt install -y python3-setuptools python3-pycryptodome python3-wheel python3-croniter \
                python3-lxml python3-netifaces python3-psutil python3-pycurl python3-slixmpp \
                python3-pip pulse-agent-linux python3-cherrypy3 python3-lmdb \
                python3-xmltodict python3-typing-extensions python3-netaddr \
                sysstat python3-pil python3-packaging python3-yaml || {
                log_error "Failed to install Medulla Agent package"
                log_error "Make sure the Medulla repository is accessible and contains pulse-agent-linux"
                exit 1
            }

            # python3-posix-ipc is not available on Ubuntu 24.04 / Zorin 18, install via pip
            if ! apt install -y python3-posix-ipc 2>/dev/null; then
                log_warn "python3-posix-ipc not available via apt, installing via pip..."
                python3 -m pip install --break-system-packages posix_ipc || true
            fi
            ;;
    esac

    # Install agent from pip if package not available
    python3 -m pip install --upgrade --break-system-packages --root-user-action=ignore \
        --no-index --find-links="tmp" ${BASE_URL}/${PULSE_AGENT_FILENAME} ${BASE_URL}/${AGENT_PLUGINS_FILENAME} 2>/dev/null || true

    [ ! -d "/var/lib/pulse2/packages" ] && mkdir -p /var/lib/pulse2/packages

    log_info "Medulla Agent installed"
}

create_service() {
    log_info "Creating systemd service..."

    local PYTHON_DIR="/usr/local/lib/python3.10/dist-packages/"

    # Detect Python version
    if [ -d "/usr/local/lib/python3.12/dist-packages/pulse_xmpp_agent" ]; then
        PYTHON_DIR="/usr/local/lib/python3.12/dist-packages/"
    elif [ -d "/usr/local/lib/python3.11/dist-packages/pulse_xmpp_agent" ]; then
        PYTHON_DIR="/usr/local/lib/python3.11/dist-packages/"
    elif [ -d "/usr/local/lib/python3.10/dist-packages/pulse_xmpp_agent" ]; then
        PYTHON_DIR="/usr/local/lib/python3.10/dist-packages/"
    fi

    mkdir -p /usr/lib/systemd/system/

    cat <<EOF > /usr/lib/systemd/system/pulse-xmpp-agent-machine.service
[Unit]
Description=Pulse2 XMPP Agent ( Machine )
After=network.target

[Service]
Type=simple
ExecStart=${PYTHON_DIR}/pulse_xmpp_agent/launcher.py -t machine
Restart=always
RestartSec=1

[Install]
WantedBy=multi-user.target
EOF

    chmod +x ${PYTHON_DIR}/pulse_xmpp_agent/launcher.py 2>/dev/null || true
}

configure_inventory() {
    TAG="$1"
    FUSION_DIR="/etc/fusioninventory"
    FUSION_CFG="${FUSION_DIR}/agent.cfg"

    if [ -f ${FUSION_CFG} ]; then
        sed -i '/^server/d' ${FUSION_CFG}
        if [ "$TAG" != "" ]; then
            echo "tag = ${TAG}" > ${FUSION_DIR}/conf.d/tag.cfg
        fi
    fi
}

start_agent() {
    log_info "Starting Medulla Agent service..."

    [ ! -d "/var/log/pulse" ] && mkdir /var/log/pulse

    systemctl daemon-reload
    systemctl enable pulse-xmpp-agent-machine.service
    systemctl restart pulse-xmpp-agent-machine.service

    sleep 3

    if systemctl is-active --quiet pulse-xmpp-agent-machine; then
        log_info "Medulla Agent service started successfully"
    else
        log_error "Failed to start Medulla Agent service"
        systemctl status pulse-xmpp-agent-machine --no-pager
        exit 1
    fi
}

verify_installation() {
    log_info "Verifying installation..."

    if systemctl is-active --quiet pulse-xmpp-agent-machine; then
        log_info "✓ Service is running"
    else
        log_warn "✗ Service is not running"
    fi

    if which fusioninventory-agent > /dev/null 2>&1; then
        log_info "✓ FusionInventory Agent is installed"
    else
        log_warn "✗ FusionInventory Agent is not installed"
    fi

    if [ -f /usr/local/share/ca-certificates/medulla-root-ca.crt ]; then
        log_info "✓ Root CA certificate is installed"
    else
        log_warn "✗ Root CA certificate is not installed"
    fi

    echo ""
    log_info "Installation completed!"
    echo ""
    log_info "You can check the agent logs with:"
    log_info "  sudo journalctl -u pulse-xmpp-agent-machine -f"
    echo ""
    log_info "The machine should appear in Medulla web interface within a few minutes."
}

main() {
    echo "========================================"
    echo "  Medulla Agent Installer"
    echo "  Zorin OS / Ubuntu 22.04 Support"
    echo "========================================"
    echo ""

    check_root
    detect_distro

    log_info "Starting installation process..."
    echo ""

    install_root_ca
    configure_repo
    install_fusioninventory
    install_agent
    create_service

    if [[ ${INVENTORY_TAG} != "" ]]; then
        configure_inventory ${INVENTORY_TAG}
    fi

    start_agent
    verify_installation

    echo ""
    echo "========================================"
    echo "  Installation Complete!"
    echo "========================================"
}

# Run main installation
main "$@"
