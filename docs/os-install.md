# OS install & first-boot hardening

This walks you from a blank Pi to a remote-accessible, Docker-ready server.

## 1. Flash the OS

1. On your laptop, install [Raspberry Pi Imager](https://www.raspberrypi.com/software/).
2. Choose **Raspberry Pi OS Lite (64-bit)** — no desktop, much less RAM used.
3. Click the gear icon (advanced options) and set:
   - Hostname (e.g., `pi5`)
   - Enable SSH → **Use public-key authentication only**, paste your `~/.ssh/id_ed25519.pub`
   - Username + (throwaway) password — you'll disable password login below anyway
   - Wi-Fi (optional, if not using Ethernet)
   - Locale, timezone
4. Write to the SD card, eject, boot the Pi.

## 2. First SSH in

From your laptop:

```bash
ssh <user>@<hostname>.local
# or use the IP from your router
```

If `.local` doesn't resolve, find the IP in your router's DHCP table.

## 3. Update everything

```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt autoremove -y
sudo reboot
```

## 4. Move root to SSD (do this before installing anything else)

With an SSD plugged into a blue USB-3 port:

1. SSH back in after reboot.
2. Run `sudo raspi-config` → **Advanced Options** → **Boot Order** → **USB Boot**.
3. Use Raspberry Pi Imager (run on your laptop, or `rpi-clone` on the Pi) to clone the SD to the SSD, *or* re-flash the SSD from scratch with the same settings.
4. Power off, remove the SD card, boot from SSD.

You can verify with:

```bash
findmnt /
# should show /dev/sda2 or /dev/nvme0n1p2, NOT /dev/mmcblk0
```

## 5. Run the bootstrap script

This installs Docker, sets up a swap file (1 GB; useful for LLM headroom), and applies a few kernel tweaks.

```bash
cd ~
git clone https://github.com/femrebora/raspberry-pi-projects.git
cd raspberry-pi-projects
bash shared/scripts/bootstrap.sh
```

Log out and back in once so your user is in the `docker` group:

```bash
exit
ssh <user>@<hostname>.local
docker ps   # should run without sudo
```

## 6. Apply the security baseline

```bash
sudo bash projects/11-security-baseline/bootstrap.sh
```

This installs `ufw`, `fail2ban`, and `unattended-upgrades`. After it finishes, only SSH (port 22), HTTP (80), and HTTPS (443) are open from the LAN.

You are now ready to pick a project from the index in [`../README.md`](../README.md).

## Going further

- **Static IP on your LAN**: edit `/etc/dhcpcd.conf` (Bookworm uses NetworkManager — `sudo nmtui` is easier).
- **Custom hostname**: `sudo hostnamectl set-hostname pi5`.
- **Avoid `.local` issues on some networks**: install Tailscale (project 04) and use the MagicDNS hostname instead.
