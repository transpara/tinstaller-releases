# Quickstart

## Install k3s

```bash
bash <(curl -sfL https://github.com/transpara/tinstaller-releases/releases/latest/download/get-and-run.sh) install-k3s
```

## Install tsystem and essentials
 
```bash
source ~/.bashrc && bash <(curl -sfL https://github.com/transpara/tinstaller-releases/releases/latest/download/get-and-run.sh) install-tsystem
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

# Repair: migrations skipped by a direct upgrade from < 0.274.0

Clusters upgraded from tStudio straight from a pre-0.274.0 install to a newer release skip all
cluster migrations (e.g. `secret "tcache-auth" not found`). Run on a control-plane node:

```bash
curl -sfL https://raw.githubusercontent.com/transpara/tinstaller-releases/main/fix-skipped-migrations.sh | bash -s -- --dry-run   # list only
curl -sfL https://raw.githubusercontent.com/transpara/tinstaller-releases/main/fix-skipped-migrations.sh | bash                   # apply
```

Pass the original version if it was not 0.272.0, e.g. `| bash -s -- 0.270.0`.

# Repair: migrations skipped by a direct upgrade from < 0.274.0

Clusters upgraded from tStudio straight from a pre-0.274.0 install to a newer release skip all
cluster migrations (e.g. `secret "tcache-auth" not found`). Run on a control-plane node:

```bash
curl -sfL https://raw.githubusercontent.com/transpara/tinstaller-releases/main/migration.sh | bash
```

Add `-s -- --dry-run` to only list pending migrations. Pass the original version if it was not
0.272.0, e.g. `| bash -s -- 0.270.0`.
