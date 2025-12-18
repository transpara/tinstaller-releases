# Quickstart

## Install k3s

```bash
curl -sfL https://github.com/transpara/tinstaller-releases/releases/latest/download/get-and-run.sh | bash -s -- install-k3s
```

## Install tsystem and essentials
 
```bash
curl -sfL https://github.com/transpara/tinstaller-releases/releases/latest/download/get-and-run.sh | bash -s -- install-tsystem
```

# Uninstall

## Clean up system (uninstall k3s and remove leftovers)

```bash
curl -sfL https://github.com/transpara/tinstaller-releases/releases/latest/download/uninstall.sh | bash -s -- --nuke-k3s
```

## Remove transpara components without affecting the rest of the cluster

```bash
curl -sfL https://github.com/transpara/tinstaller-releases/releases/latest/download/uninstall.sh | bash -s --
```
