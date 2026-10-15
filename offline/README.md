# Offline (air-gapped) installation

The `drawio` Claude Code plugin with draw.io Desktop, on a network with no internet access. Claude creates draw.io diagrams (flowcharts, architecture, network, ERD, sequence and more), saves them as `.drawio` files, and can export them to PNG, SVG or PDF.

All files are in the [`offline-kit-v32.4.1`](https://github.com/EliShteinman/drawio-mcp/releases/tag/offline-kit-v32.4.1) release. The Windows installer comes from the official [draw.io Desktop](https://github.com/jgraph/drawio-desktop/releases/tag/v32.4.1) release.

## Requirements

- Claude Code installed
- git (only for the GitLab step)

## 1. Download the files (on a Windows machine with internet)

| File | Size | What it is |
|---|---|---|
| [`drawio-mcp.bundle`](https://github.com/EliShteinman/drawio-mcp/releases/download/offline-kit-v32.4.1/drawio-mcp.bundle) | 8.4MB | The full repo, with history |
| [`drawio-offline-el8-x86_64.tar.gz`](https://github.com/EliShteinman/drawio-mcp/releases/download/offline-kit-v32.4.1/drawio-offline-el8-x86_64.tar.gz) | 215MB | draw.io + every dependency for RHEL / Rocky / Alma 8 |
| [`drawio-offline-el9-x86_64.tar.gz`](https://github.com/EliShteinman/drawio-mcp/releases/download/offline-kit-v32.4.1/drawio-offline-el9-x86_64.tar.gz) | 243MB | draw.io + every dependency for RHEL / Rocky / Alma 9 |
| [`SHA256SUMS.txt`](https://github.com/EliShteinman/drawio-mcp/releases/download/offline-kit-v32.4.1/SHA256SUMS.txt) | 1KB | Checksums of the three files above |
| [`draw.io-32.4.1-windows-installer.exe`](https://github.com/jgraph/drawio-desktop/releases/download/v32.4.1/draw.io-32.4.1-windows-installer.exe) | 137MB | draw.io for Windows |
| [`Files-SHA256-Hashes.txt`](https://github.com/jgraph/drawio-desktop/releases/download/v32.4.1/Files-SHA256-Hashes.txt) | 3KB | Official checksums of the Windows installer |

To download everything at once in PowerShell (every line at the end should start with `OK`):

```powershell
$dir = "$HOME\Downloads\drawio-offline"
New-Item -ItemType Directory -Force $dir | Out-Null
Set-Location $dir
$kit = "https://github.com/EliShteinman/drawio-mcp/releases/download/offline-kit-v32.4.1"
$app = "https://github.com/jgraph/drawio-desktop/releases/download/v32.4.1"
$urls = "$kit/drawio-mcp.bundle", "$kit/drawio-offline-el8-x86_64.tar.gz",
        "$kit/drawio-offline-el9-x86_64.tar.gz", "$kit/SHA256SUMS.txt",
        "$app/draw.io-32.4.1-windows-installer.exe", "$app/Files-SHA256-Hashes.txt"
foreach ($u in $urls) { curl.exe -fL -O $u }
Get-Content SHA256SUMS.txt, Files-SHA256-Hashes.txt | ForEach-Object {
  $hash, $name = $_ -split '\s+', 2
  if (Test-Path $name) {
    $ok = (Get-FileHash $name -Algorithm SHA256).Hash -eq $hash
    "{0}  {1}" -f $(if ($ok) { "OK  " } else { "FAIL" }), $name
  }
}
```

Move the `drawio-offline` folder into the internal network through your usual process.

## 2. Push the repo to GitLab (once)

From any internal machine with git:

```bash
git clone drawio-mcp.bundle drawio-mcp
cd drawio-mcp
git remote set-url origin https://<gitlab-host>/<group>/drawio-mcp.git
git push -u origin --all
```

## 3. Install draw.io Desktop

### Linux (RHEL / Rocky / Alma 8 or 9)

Check the version with `cat /etc/redhat-release` and use the matching file, el8 or el9:

```bash
tar xzf drawio-offline-el9-x86_64.tar.gz
sudo ./drawio-offline-el9/install.sh
drawio --version
```

What `install.sh` does:

- **The machine has a reachable repo (Artifactory or Satellite):** every package available there is installed from it. The kit supplies only what's missing, at least draw.io itself.
- **The repo is unreachable, or no repo is configured:** it is skipped, and everything comes from the kit.
- **The repo answers but a package download fails:** the install stops without changing anything and retries from the kit only.
- **Nothing already installed is changed.** Only missing packages are added.
- **`drawio` works on servers with no display.** The install adds `/usr/local/bin/drawio`, a wrapper that runs draw.io through `xvfb-run` when there is no display, and adds `--no-sandbox` only when running as root or when user namespaces are disabled.

The kit's packages come from Rocky Linux, which is binary-compatible with RHEL. GPG checking is disabled for the kit only, because RHEL machines don't have Rocky's key. Check the kit's integrity instead with the SHA256 checksums in step 1.

### Windows

Run `draw.io-32.4.1-windows-installer.exe`. Windows needs no extra dependencies.

## 4. The plugin in Claude Code

```
/plugin marketplace add https://<gitlab-host>/<group>/drawio-mcp.git
/plugin install drawio@drawio
```

Restart Claude Code, then test:

```
/drawio:drawio png flowchart for user login
```

You can also just ask in plain language, e.g. "draw me a diagram of ...".

## Limitations

- `url` mode doesn't work offline, because it opens app.diagrams.net. `.drawio` files and image exports work normally.
- Without draw.io Desktop, the plugin only creates `.drawio` files from XML: no Mermaid, no image export.

## What was tested

On RHEL 8.10 and RHEL 9.8 (Red Hat UBI images):

- Install in three situations: repo unreachable (including a configured Artifactory that doesn't answer), repo available, and repo answering but failing mid-download.
- Running as root and as a regular user, with and without the sandbox.
- Mermaid conversion, ELK layout (`--layout`), and PNG / SVG / PDF export, with networking fully disabled.

## Rebuilding the kit (for a new draw.io version)

On a machine with Docker and internet:

```bash
DRAWIO_VERSION=32.4.1 ./offline/build-kit.sh
```

The script writes both Linux kits, `drawio-mcp.bundle` and `SHA256SUMS.txt` to `offline/dist/`. Upload those files to a new release.

- `offline/kit/packages.txt` lists the system packages shipped with draw.io. It exists because the draw.io RPM doesn't declare everything it needs (for example `alsa-lib` and `mesa-libgbm`).
- After merging from upstream, run `./scripts/sync-skill-references.sh` first, then build the kit.
