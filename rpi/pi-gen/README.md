# rpi/pi-gen — 预安装 PaperMC 的树莓派镜像构建

基于官方 [pi-gen](https://github.com/RPi-Distro/pi-gen) 在 **stage2（基础系统，无桌面）** 之上插入自定义 `stage-mc`，产出开机即带 Java + PaperMC systemd 服务的 `.img.xz`。

## 与 main 分支 cloud-init 方案的区别

| 维度 | main（cloud-init） | rpi-image-build（pi-gen） |
| --- | --- | --- |
| 镜像 | 官方 Ubuntu/Pi OS 镜像 | 自定义镜像，预装 Java + 服务 |
| 首次启动 | 联网下载 PaperMC + 安装（5-10 分钟） | 仅联网下载 jar（1-2 分钟） |
| 离线首启 | ❌ 需要联网 | ⚠️ 仍需联网下载 jar，但系统已就绪 |
| 可定制性 | 改 YAML 即可 | 需重新构建镜像 |
| 适用 | 快速部署/批量 | 固化出厂镜像 |

## 本地构建

依赖：**Docker**（pi-gen 用 docker buildx 构建，需要 root）。

```bash
cd rpi/pi-gen
bash build-custom.sh
# 产物: work/pi-gen/deploy/image_mc-pi_*.img.xz
```

构建产物约 1.5-2 GB，首次构建 30-60 分钟。

## 镜像烧录后

1. 烧录 `.img.xz` 到 SD 卡（Raspberry Pi Imager 或 dd）
2. 上电，首次启动会联网下载 PaperMC jar 到 `/opt/mc-server/paper.jar`
3. SSH 登录后编辑 `/opt/mc-server/eula.txt` 把 `eula=false` 改成 `eula=true`
4. `sudo systemctl restart mcserver`
5. 端口 25565

## CI 构建

[`.github/workflows/build-image.yml`](../../.github/workflows/build-image.yml) 在 `rpi-image-build` 分支推送时触发，用 self-hosted runner 或 Docker 构建并上传产物到 GitHub Release。**注意**：pi-gen 构建需要较长时间和较大磁盘（20GB+），GitHub 托管 runner 可能超时/空间不足，建议用 self-hosted runner。
