# Proxmox Scripts
based on https://tteck.github.io/Proxmox/ Scripts

## Proxmox remove and extend volume

Click on *Datacenter*, go to *Storage* and remove *local-lvm*

Go into console and run the following commands:

* Remove data logical volume
```yaml
lvremove /dev/pve/data
```

* resize root logical volume
```yaml
lvresize -l 100%FREE /dev/pve/root
```

* resize root mapper
```yaml
resize2fs /dev/mapper/pve-root
```

## Proxmox Post Install script:

<p align="center"><img src="https://raw.githubusercontent.com/Atlas34/proxmox/main/images/proxmox.png" height="100"/></p>

The script will give options to Disable the Enterprise Repo, Add/Correct PVE7 Sources, Enable the No-Subscription Repo, Add Test Repo, Disable Subscription Nag and Update Proxmox VE.
 
Run the following in the Proxmox Shell. ⚠️ **PVE7 ONLY**

```yaml
bash -c "$(wget -qLO - https://github.com/atlas34/proxmox/raw/main/proxmox-post-install.sh)"
```

## Proxmox Dark Theme:

<p align="center"><img src="https://raw.githubusercontent.com/Atlas34/proxmox/main/images/proxmox_dark_theme.png" height="100"/></p>

 Dark theme for the Proxmox Web UI is a custom theme created by [Weilbyte](https://github.com/Weilbyte/PVEDiscordDark) that changes the look and feel of the Proxmox web-based interface to a dark color scheme. 

```yaml
bash <(curl -s https://raw.githubusercontent.com/Weilbyte/PVEDiscordDark/master/PVEDiscordDark.sh ) install
```

To uninstall the theme, simply run the script with the ```uninstall``` command.

## Proxmox Install Jellyfin in LXC container

<p align="center"><img src="https://raw.githubusercontent.com/atlas34/proxmox/main/images/jellyfin.png" height="100"/></p>

To create a new Proxmox Jellyfin Media Server LXC, run the following in the Proxmox Shell.

```yaml
bash -c "$(wget -qLO - https://github.com/atlas34/proxmox/raw/main/proxmox-lxc-jellyfin.sh)"
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

<p align="center"><img src="https://raw.githubusercontent.com/atlas34/proxmox/main/images/docker.png" height="100"/></p>

To create a new Proxmox Docker LXC, run the following in the Proxmox Shell.

```yaml
bash -c "$(wget -qLO - https://github.com/atlas34/proxmox/raw/main/proxmox-lxc-docker.sh)"
```

⚡ Default Settings:  2GB RAM - 8GB Storage - 2vCPU ⚡

**Portainer Interface - IP:9000**

⚙️ **To Update**

Run in the LXC console
```yaml
apt update && apt upgrade -y
```
## Proxmox Install Home Assistant in DOCKER LXC container

<p align="center"><img src="https://raw.githubusercontent.com/atlas34/proxmox/main/images/homeassistant.png" height="100"/></p>

 ⚠️ **Install Docker container before running this script**

To add a new docker Home Assistant Container, run the following command in the Proxmox Shell.
 
```yaml
bash -c "$(wget -qLO - https://github.com/atlas34/proxmox/raw/main/proxmox-lxc-homeassistant.sh)"
```

After install, reboot Home Assistant and **clear browser cache** then Add HACS integration.

