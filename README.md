# Quickstart

## Install k3s

```bash
rm -f install-k3s && curl -#LO "https://github.com/transpara/tinstaller-releases/releases/download/$(curl -s "https://api.github.com/repos/transpara/tinstaller-releases/releases/latest" | jq -r '.tag_name')/install-k3s" && chmod +x install-k3s && ./install-k3s
```

## Install tsystem and essentials
 
```bash
rm -f install-tsystem && curl -#LO "https://github.com/transpara/tinstaller-releases/releases/download/$(curl -s "https://api.github.com/repos/transpara/tinstaller-releases/releases/latest" | jq -r '.tag_name')/install-tsystem" && chmod +x install-tsystem && ./install-tsystem
```

# Uninstall

## Clean up system (uninstall k3s and remove leftovers)

```bash
rm -f uninstall-tsystem && VERSION=$(kubectl get tsystem -o jsonpath='{..spec.tSystemApi.config.TINSTALLER_VERSION}' | awk '{print $1}') && curl -#LO "https://github.com/transpara/tinstaller-releases/releases/download/$VERSION/uninstall-transpara.sh" && chmod +x uninstall-transpara.sh && ./uninstall-transpara.sh --nuke-k3s
```

## Remove transpara components without affecting the rest of the cluster

```bash
rm -f uninstall-tsystem && VERSION=$(kubectl get tsystem -o jsonpath='{..spec.tSystemApi.config.TINSTALLER_VERSION}' | awk '{print $1}') && curl -#LO "https://github.com/transpara/tinstaller-releases/releases/download/$VERSION/uninstall-transpara.sh" && chmod +x uninstall-transpara.sh && ./uninstall-transpara.sh
```
