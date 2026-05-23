# Hardware setup

You can run every project in this repo on a stock Raspberry Pi 5 (8 GB), but two pieces of hardware turn it from "a toy" into "a 24/7 server": a real cooler and an SSD. Everything else is optional.

## Required

| Item | Why | Cost (USD, May 2026) |
|---|---|---|
| Raspberry Pi 5, 8 GB | The host | ~$80 |
| **Official 27 W USB-C PSU** | The Pi 5 throttles under 5 V/5 A; cheaper supplies cause random reboots | ~$12 |
| **Active Cooler** (or Pi 5 Case with fan) | LLM inference sustains 100 % CPU; without it you will thermal-throttle within a minute | ~$8 |
| microSD card (32 GB+, A2) | First boot only; you will move the OS off it | ~$8 |

## Strongly recommended

| Item | Why |
|---|---|
| **USB 3.0 SSD (256 GB+) or NVMe HAT + NVMe SSD** | microSD cards die in weeks under Docker / log / database write load. Move the root filesystem to SSD after first boot — see [`os-install.md`](os-install.md). |
| **Ethernet cable** | Tunnels and large model downloads are happier on wired; Wi-Fi works but adds latency. |

## Optional

| Item | When you want it |
|---|---|
| UPS HAT (e.g., Waveshare UPS HAT (E), PiSugar) | Your power flickers; you care about graceful shutdown on outage |
| AI HAT+ / Hailo-8 accelerator | You want serious local inference. Out of scope for this repo — Ollama/llama.cpp on CPU is the baseline. |
| RTC battery (CR2032 with backup HAT) | The Pi needs accurate time at boot before `chrony` syncs; relevant for offline use only |

## Why an SSD, in one line

The Pi 5 boots from USB or NVMe natively. A microSD has ~10 k write-cycles per cell; Docker's overlay filesystem and SQLite-backed apps (Uptime Kuma, Vaultwarden, etc.) churn through that budget in **weeks**. An SSD will last years.

## Thermal sanity check

After bootstrap, run:

```bash
vcgencmd measure_temp
```

Idle should be **< 55 °C**. Under load (e.g., during an Ollama generate), it should stay **< 80 °C**. If you see `throttled=0x...` from `vcgencmd get_throttled`, the cooling or PSU is inadequate.
