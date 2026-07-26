# GTNH-OC-AE-Controller Backend

一个使用 **Zig 0.16.0** 编写的轻量级后端服务，面向 GTNH / OC / AE 相关场景，提供命名空间申请、受限资源访问、JSON 数据持久化以及简单缓存回写能力。

## 特性

- 命名空间申请与令牌鉴权
- 基于 `httpz` 的 HTTP 服务
- 文件型持久化后端
- LRU 缓存与定时回写
- CORS 支持
- 资源按命名空间隔离
- 支持对象型 JSON 与数组型 JSON 的增删改查

## 项目结构

- `src/main.zig`：程序入口，负责读取配置、初始化服务和注册路由
- `src/config.zig`：配置加载与默认配置生成
- `src/namespace.zig`：命名空间管理、过期、持久化与清理
- `src/apply_handler.zig`：命名空间申请接口
- `src/object_handler.zig`：对象型 JSON 资源处理
- `src/array_handler.zig`：数组型 JSON 资源处理
- `src/json_data.zig`：JSON 数据抽象与文件存储实现
- `src/lru.zig`：通用 LRU 缓存
- `src/timer.zig`：后台定时器
- `src/cors.zig`：CORS 中间件封装

## 构建要求

- Zig **0.16.0**
- 可用的网络环境，用于首次拉取依赖

依赖：

- `httpz`

## 构建与运行

首次拉取依赖：

```bash
zig build --fetch
```

构建：

```bash
zig build
```

运行：

```bash
zig build run
```

默认会监听配置中的端口。首次启动时，如果配置文件不存在，程序会自动生成默认配置。

## 配置说明

配置文件路径会优先读取环境变量 `OC_AE_BACKEND_CONFIG`, 若环境变量不存在则会使用默认路径 `./config.json`

所有配置说明可见: [config.zig](./src/config.zig)

常用配置项如下：

```json
{
  "port": 16500,
  "lru_capacity": 16,
  "url_prefix": "/ocae",
  "mode": "json",
  "json_data_path": "./data",
  "saver_period_second": 60,
  "namespace": {
    "mode": "json",
    "json_file": "./data/namespaces.json",
    "rental_period_seconds": 604800,
    "namespace_length": 32,
    "token_length": 32,
    "secure_random": true,
    "candidate": "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_"
  },
  "apply_handler": {
    "url_prefix": "",
    "max_request_count": 1,
    "max_request_count_period_ms": 60000
  }
}
```

### 关键配置项

- `port`：HTTP 监听端口
- `url_prefix`：除申请接口外，其余资源接口的公共前缀，默认是 `/ocae`
- `json_data_path`：资源 JSON 文件的存储根目录，默认 `./data`
- `saver_period_second`：定时回写间隔，单位秒
- `namespace.json_file`：命名空间持久化文件
- `namespace.rental_period_seconds`：命名空间租期，单位秒
- `apply_handler.max_request_count`：单 IP 限流窗口内最大申请次数
- `apply_handler.max_request_count_period_ms`：限流窗口，单位毫秒；设为 `0` 表示不启用限流

## 路由说明

### 命名空间申请

```http
GET /apply
```

返回示例：

```json
{
  "code": "200",
  "message": "success",
  "data": {
    "url": "/ocae/<namespace>",
    "token": "<token>"
  }
}
```

### 对象型资源

当前内置资源名：

- `task`
- `items`
- `essentia`
- `fluids`

接口形式：

```http
GET /ocae/:namespace/<name>
PUT /ocae/:namespace/<name>
```

其中 `<name>` 为上面的资源名之一。

### 数组型资源

当前内置资源名：

- `cpus`

接口形式：

```http
GET    /ocae/:namespace/cpus
PUT    /ocae/:namespace/cpus

GET    /ocae/:namespace/cpus/:id
PUT    /ocae/:namespace/cpus/:id
DELETE /ocae/:namespace/cpus/:id
```

## 鉴权方式

受限资源接口需要在请求头中携带：

```http
ocaetoken: <token>
```

这个 token 会在申请命名空间时返回。

## 数据存储

- 命名空间信息写入 `namespace.json_file`
- 业务数据写入 `json_data_path` 下的对应目录
- 缓存会在以下时机写回磁盘：
  - LRU 淘汰
  - 后台定时回写
  - 服务退出前的清理阶段

## 设计概览

后端采用了三层思路：

1. **申请层**：创建命名空间并返回访问 URL 与 token
2. **鉴权层**：校验 `ocaetoken`，并根据命名空间状态决定是否允许访问
3. **数据层**：将 JSON 资源缓存到内存，并周期性写回文件

这种结构适合轻量、专用、数据规模较小的场景。

## 注意事项

- `x-forwarded-for` 会被用于申请接口的限流统计；如果前面没有可信反代，建议谨慎部署
- 当前资源结构以 JSON 为中心，适合简单数据，不适合复杂事务型数据
- 命名空间和资源文件都依赖本地文件系统，请确保运行目录有写权限

## 许可证

MIT
