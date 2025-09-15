# Quickstart

## Install k3s

```bash
curl -s -L -O "https://github.com/transpara/tinstaller-releases/releases/download/$(curl -s "https://api.github.com/repos/transpara/tinstaller-releases/releases/latest" | jq -r '.tag_name')/install-k3s" && chmod +x install-k3s && ./install-k3s
```

## Install tsystem and essentials
 
```bash
curl -s -L -O "https://github.com/transpara/tinstaller-releases/releases/download/$(curl -s "https://api.github.com/repos/transpara/tinstaller-releases/releases/latest" | jq -r '.tag_name')/install-tsystem && chmod +x install-tsystem && ./install-tsystem
```
 
