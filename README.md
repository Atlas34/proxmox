# Proxmox Scripts
based on https://tteck.github.io/Proxmox/ Scripts

## Proxmox Post Install script:

The script will give options to Disable the Enterprise Repo, Add/Correct PVE7 Sources, Enable the No-Subscription Repo, Add Test Repo, Disable Subscription Nag and Update Proxmox VE.
 
Run the following in the Proxmox Shell. ⚠️ **PVE7 ONLY**

```yaml
bash -c "$(wget -qLO - https://github.com/atlas34/proxmox/raw/proxmox-post-install.sh)"
```

## Proxmox Install Jellyfin in LXC container

To create a new Proxmox Jellyfin Media Server LXC, run the following in the Proxmox Shell.

```yaml
bash -c "$(wget -qLO - https://github.com/atlas34/proxmox/raw/proxmox-lxc-jellyfin.sh)"
```
⚡ Default Settings:  2GB RAM - 8GB Storage - 2vCPU ⚡

**Jellyfin Media Server Interface - IP:8096**

FFmpeg path: `/usr/lib/jellyfin-ffmpeg/ffmpeg`

⚙️ **To Update Jellyfin Media Server**

Run in the LXC console
```yaml
apt update && apt upgrade -y
```

## Proxmox Install Docker in LXC container

To create a new Proxmox Docker LXC, run the following in the Proxmox Shell.

```yaml
bash -c "$(wget -qLO - https://github.com/atlas34/proxmox/raw/proxmox-lxc-docker.sh)"
```

⚡ Default Settings:  2GB RAM - 8GB Storage - 2vCPU ⚡

**Portainer Interface - IP:9443**

⚙️ **To Update**

Run in the LXC console
```yaml
apt update && apt upgrade -y
```
