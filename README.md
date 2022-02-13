An automated script to install and configure cPanel/WHM. The script help to save time during setting up a cPanel server for production usage.

## How to run?

curl -LsO raw.githubusercontent.com/khalequzzaman17/cpanelconfig/main/app.sh && sh app.sh

## Supported OS?
> CentOS 6.x/7.x/8.x 64bit

---

### Standard PHP Settings
* max_execution_time = 180
* max_input_time = 180
* max_input_vars = 3000
* memory_limit = 128M
* post_max_size = 64M
* upload_max_filesize = 64M
