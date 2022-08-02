An automated script to install and configure cPanel/WHM. The script help to save time during setting up a cPanel server for production usage.

## How to run?

```
curl -Ls raw.githubusercontent.com/khalequzzaman17/cpanelconfig/main/app.sh | bash
```

## Supported OS?
> CentOS 6.x/7.x/8.x 64bit

> AlmaLinux 8.x/9.x 64bit

> Ubuntu 20.04 LTS

---

### Standard PHP Settings
* max_execution_time = 180
* max_input_time = 180
* max_input_vars = 3000
* memory_limit = 128M
* post_max_size = 64M
* upload_max_filesize = 64M
