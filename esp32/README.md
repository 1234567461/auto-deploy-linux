# ESP32-S3 最小 Linux

ESP32-S3 上跑 Linux 属于 **实验性质**：芯片没有 MMU、RAM 小，只能跑 BusyBox 级 initramfs，**无法运行 Minecraft**（内存与算力都不够）。本目录提供自动烧录现成镜像的脚本，用于学习/探索 Linux-on-MCU。

## 镜像来源

使用 [paulneja/Linux-on-esp32-S3](https://github.com/paulneja/Linux-on-esp32-S3) 的预构建镜像：

- Linux 6.11 内核，**Xtensa 原生**（非模拟器），跑在 ESP32-S3 自身核心上
- WiFi 与 Linux 并存：Espressif 固件留在同片上，Linux 通过驱动访问
- 硬件 RSA 加速器对 Linux 暴露
- shell 通过 telnet 或串口获得

启动链：
```
ESP ROM -> ESP-IDF second stage -> loader -> Linux -> BusyBox initramfs
```

## 烧录

```bash
# 默认 /dev/ttyACM0 @ 921600
./flash-esp32.sh

# 指定端口
./flash-esp32.sh --port /dev/ttyUSB0

# 只下载源码不烧录
./flash-esp32.sh --clone-only
```

脚本会：`pip install esptool` → `git clone` 上游仓库 → 调用上游 `flash.sh`。

## 烧录后访问

串口：
```bash
screen /dev/ttyACM0 115200
```

WiFi（需先在串口里配 `wpa_supplicant.conf`）：
```bash
telnet <esp32-ip>
```

## 硬件要求

- ESP32-S3，**16MB Flash + 8MB PSRAM**（N16R8 模组），如 DevKitC-1 N16R8
- USB 数据线（Type-C，能传数据不是只能充电）
- 上游已验证型号见其仓库 README

## ESP32 vs 树莓派

| 维度 | ESP32-S3 | 树莓派 Pi 4/5 |
| --- | --- | --- |
| Linux 形态 | 最小 BusyBox initramfs | 完整 Debian/Ubuntu |
| RAM | ~8MB PSRAM | 2-8GB DDR |
| 存储 | 16MB Flash | SD/SSD 数十 GB |
| Minecraft | ❌ 跑不动 | ✅ PaperMC 服务器 |
| 部署目的 | Linux-on-MCU 学习 | 实用服务托管 |

要在树莓派上跑 MC，回到 [`../rpi/`](../rpi/) 目录。
