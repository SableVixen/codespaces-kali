#!/bin/sh
set -eu
KALI_CONTAINER=kali
KALI_IMAGE=kalilinux/kali-rolling
WORKSPACE=/workspace

echo "[+] Starting Kali setup"

[ -f /etc/os-release ] && . /etc/os-release && echo "[+] OS: $PRETTY_NAME"

if ! command -v docker >/dev/null 2>&1; then
 apt update
 apt install -y docker.io
 service docker start || true
fi

if ! docker ps -a --format '{{.Names}}' | grep -q "^$KALI_CONTAINER$"; then
 docker pull "$KALI_IMAGE"
 docker run -dit --name "$KALI_CONTAINER" --hostname kali --restart unless-stopped --privileged -v "$PWD:$WORKSPACE" -w "$WORKSPACE" "$KALI_IMAGE" bash
else
 echo "[+] Kali container already exists"
fi

echo "[+] Configuring Kali..."

docker exec "$KALI_CONTAINER" bash -c '
set -e
apt update
apt install -y sudo kali-linux-headless kali-tools-top10 bash-completion zsh tmux git curl wget vim nano python3 python3-pip python3-venv pipx ruby golang openjdk-21-jdk build-essential cmake gdb strace ltrace lsof ripgrep fd-find fzf jq yq tree htop btop dnsutils whois iproute2 net-tools netcat-openbsd tcpdump nmap masscan amass dnsrecon subfinder httpx-toolkit whatweb nikto gobuster feroxbuster ffuf sqlmap hydra john hashcat aircrack-ng tshark shellcheck shfmt

id kali >/dev/null 2>&1 || {
 groupadd -g 1000 kali || true
 useradd -m -u 1000 -g 1000 -s /bin/bash kali
}

usermod -aG sudo kali
echo "kali ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/kali
chmod 440 /etc/sudoers.d/kali

mkdir -p /workspace
chown -R kali:kali /workspace
chmod -R u+rwX /workspace

su - kali -c "
mkdir -p ~/tools ~/wordlists ~/payloads ~/scripts ~/projects
cat > ~/.bash_aliases <<EOF
alias ll=\"ls -lah\"
alias ports=\"ss -tulnp\"
alias update=\"sudo apt update && sudo apt full-upgrade -y\"
alias py=\"python3\"
alias c=\"clear\"
EOF
"

chsh -s /bin/bash kali
echo "[+] Kali configuration complete"
'

echo
echo "================================"
echo " Kali is ready"
echo "================================"
echo
echo "Enter:"
echo
echo "docker exec -it kali bash"
