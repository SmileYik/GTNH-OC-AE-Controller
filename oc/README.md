# OC-AE

该程序能够在 GTNH 原版包中实现网页端控制AE网络中物品的合成以及查看网络中的物品和流体。

目前实现的功能有：

* 搜寻网络中的物品
* 获取网络中所有流体
* 获取网络中所有源质
* 获取网络中所有 CPU 信息
* 请求网络制作指定物品
* 监控 CPU 工作状态直至 CPU 空闲

### 工作原理

OC 机器轮询访问某一网络链接地址，获取指令，根据指令去执行已经设定好的方法。
指令为 JSON 格式内容，模板为：
```json
{
   "method": "任务方法名",
   "data": {}
}
```

`data` 为相应参数，在 `main.lua` 中含有方法的参数说明。

### OC 设备需求

1. 装有因特网网卡的PC机
2. 紧贴着ME接口的适配器
3. 至少2根 T1 内存条
4. OpenOS

### 安装程序

在装有因特网卡以及OpenOS的电脑上运行以下指令进行安装：

```
wget https://github.com/SmileYik/GTNH-OC-AE-Controller/raw/refs/heads/master/oc/installer.lua ./oc-ae-installer.lua && ./oc-ae-installer.lua --target-direcory "/home/oc-ae"
```

或者

```
wget https://ocae.smileyik.eu.org/oc/installer.lua ./oc-ae-installer.lua && ./oc-ae-installer.lua --target-direcory "/home/oc-ae"
```

### 使用方法

将本目录中所有 lua 脚本文件全部拷贝到 oc 硬盘后，修改完配置文件，使用 `main` 运行程序。

配置文件在 `config.lua` 中， 其中默认内容如下：

```
return {
    sleep = 10,                     -- 两次执行任务时间隔多少秒
    token = "token",                -- token，若后端不需要校验token则可随便填写
    baseUrl = "https://SERVER_URL/user/YOUR_TOKEN",     -- 基础 url，后端路径，也是你在前端输入的 url
    path = {                        -- 各项数据路径
        task = "/task",             -- 任务数据所在路径
        cpu = "/cpus",              -- cpu
        essentia = "/essentia",     -- 源质
        fluids = "/fluids",         -- 流体
        items = "/items"            -- 物品
    }
}
```

### 鉴权相关

* OC电脑在向后端发送HTTP请求时会附带一个名为 `ocaetoken` 的 header 作为凭据
