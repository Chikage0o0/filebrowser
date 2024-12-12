## FileBrowser Docker 部署

提供了额外的PUID、PGID以及UMASK环境变量，以便与使用宿主机用户的UID和GID进行文件操作。

```shell
docker run -d \
  --name=filebrowser \
  -e PUID=1000 \
  -e PGID=1000 \
  -e UMASK=002 \
  -e PORT=80 \
  -e WORK_SPACE=/data \
  -e TZ=Asia/Shanghai \
  -p 80:80 \
  -v ./data:/data \
  --restart unless-stopped \
  ghcr.io/chikage0o0/filebrowser:latest
```