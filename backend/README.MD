### 后端配置

后端使用的 [json-server](https://github.com/typicode/json-server)

json-server 运行的初始json文件内容如下：
```
{
  "items": {},      // 物品数据
  "cpus": [],       // cpu数据
  "essentia": {},   // 源质数据
  "fluids": {},     // 流体数据
  "task": {}        // 任务数据
}
```

使用命令 `json-server oc.json` 开启一个简单的后端服务器

* OC电脑在向后端发送HTTP请求时会附带一个名为 `ocaetoken` 的 header 作为凭据
