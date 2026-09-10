# rpi/mc-server

PaperMC 在树莓派上的部署工件。**权威版本嵌在 [cloud-init/user-data](../cloud-init/user-data) 的 `write_files` 块里**，首次启动时由 cloud-init 写入。本目录提供可独立运行的副本，便于本地预览/调试。

| 文件 | 作用 | 部署后位置 |
| --- | --- | --- |
| `install-paper.sh` | 下载指定版本的 PaperMC jar，生成 `eula.txt` | `/opt/mc-server/install-paper.sh` |
| `server.properties` | MC 服务器配置（端口、玩家数、视距、motd） | `/opt/mc-server/server.properties` |
| `mcserver.service` | systemd 单元，开机自启、崩溃重启 | `/etc/systemd/system/mcserver.service` |

## 手动安装（已登录的 Pi 上）

```bash
sudo mkdir -p /opt/mc-server && sudo chown $USER /opt/mc-server
cp install-paper.sh server.properties /opt/mc-server/
sudo cp mcserver.service /etc/systemd/system/
cd /opt/mc-server
MC_VERSION=1.21.4 MC_EULA=true bash install-paper.sh
sudo systemctl daemon-reload
sudo systemctl enable --now mcserver
journalctl -u mcserver -f
```

## 关键参数

- **Java**: `openjdk-21-jre-headless`（MC 1.20.5+ 要求 Java 21）
- **内存**: `-Xmx1G` 适合 Pi 4 (2GB)；Pi 4 4GB/8GB 或 Pi 5 可调到 `-Xmx2G`/`-Xmx4G`
- **端口**: 25565（已通过 ufw 放行）
- **EULA**: 必须显式接受，部署时 `--mc-eula true` 或在 `eula.txt` 写 `eula=true`
- **online-mode**: 默认 `true`（需正版账号）；离线/局域网用改 `false`

## 性能建议

- Pi 5 用 SSD 启动比 SD 卡快很多，世界加载延迟显著降低
- `view-distance=8` 平衡视距与内存；降到 6 可省内存
- 长开服务建议加 `tmux`/`screen`，但本部署已用 systemd 托管，无需手动 detach
