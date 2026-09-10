# auto-deploy-linux

一键自动部署 Linux 到 **树莓派 (Pi 4/5)** 和 **ESP32-S3**，并在树莓派上开机即跑 [Minecraft](https://www.minecraft.net/) 服务器（PaperMC）。

## 平台能力对比

| 平台 | 部署方式 | Linux 形态 | 能否跑 Minecraft |
| --- | --- | --- | --- |
| 树莓派 Pi 4/5 | SD 卡镜像 + cloud-init | 完整 Debian/Ubuntu | ✅ 跑 PaperMC 服务器 |
| ESP32-S3 | esptool 烧录预构建镜像 | 最小 BusyBox / Xtensa Linux | ❌ 内存与算力不足，仅作 Linux 实验 |

## 仓库结构

```
.
├── rpi/                   # 树莓派：cloud-init + MC 服务器
│   ├── deploy.sh          # 烧录镜像并注入 cloud-init
│   ├── cloud-init/        # user-data / network-config / meta-data
│   └── mc-server/         # PaperMC 安装脚本 + systemd 服务
└── esp32/                 # ESP32-S3：最小 Linux 烧录
    └── flash-esp32.sh
```

## 树莓派快速开始

```bash
cd rpi
sudo ./deploy.sh \
  --image ubuntu-24.04-preinstalled-server-arm64+raspi.img.xz \
  --device /dev/sdX \
  --hostname mc-pi \
  --wifi-ssid MySSID --wifi-psk MyPassword
```

插卡开机，cloud-init 完成（约 5-10 分钟，含 Java + PaperMC 下载）后，MC 服务器在 25565 端口监听：

```bash
ssh mc-pi.local
systemctl status mcserver
```

## ESP32 快速开始

```bash
cd esp32
./flash-esp32.sh --port /dev/ttyACM0
```

> ESP32 上的 Linux 仅为实验性质：16MB PSRAM 跑 BusyBox initramfs，telnet/串口 shell，**不能运行 Minecraft**。详见 [esp32/README.md](esp32/README.md)。

## 致谢

- 树莓派 cloud-init 流程参考 [Raspberry Pi 官方 cloud-init 文档](https://www.raspberrypi.com/news/cloud-init-on-raspberry-pi-os/)
- ESP32-S3 Linux 镜像来自 [paulneja/Linux-on-esp32-S3](https://github.com/paulneja/Linux-on-esp32-S3)
- PaperMC 来自 [PaperMC](https://papermc.io/)

## License

MIT
