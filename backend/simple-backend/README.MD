### simple-backend

SimpleBackend 是一个带有简单的凭据验证，支持 `If-Modified-Since` 请求头，且为最小化支持 OC-AE 所提出来的后端要求的一个 Spring 实现。

#### 构建

首先确保已经安装好 JDK17, 在确保安装好 JDK17 后，运行以下指令进行编译:

```
./gradlew bootJar
```

编译完成后，会在 `./build/libs/` 下新增一个可执行的 jar 包文件。

#### 如何使用

使用指令 `java -jar xxxx.jar <config file>` 进行运行。

配置文件模板位置在 `./src/main/resources/config-template.json`, 其默认的内容如下:

```
{
  "port": 60081,
  "token": "123456",
  "controller": {
    "/items": "Object",
    "/cpus": "Array",
    "/task": "Object",
    "/fluids": "Object",
    "/essentia": "Object"
  }
}
```

将其复制一份，并存放在编译出来的 jar 包同一目录下，使用 `java -jar xxxx.jar xxx.json` 运行。

##### 配置文件

```
{
  "port": 60081,           // 后端端口
  "token": "123456",       // 验证凭据
  "controller": {          // 控制器
    "/items": "Object",
    "/cpus": "Array",
    "/task": "Object",
    "/fluids": "Object",
    "/essentia": "Object"
  },
  "enableMultiuser": false,              // 是否启用多用户
  "userFile": "users.json",              // 用户文件
  "prefixPath": "/user",                 // 请求路径前缀
  "reentTableFile": "reent-table.json",  // 租借表
  "maxReentFreeTime": 604800000          // 最大空闲租借时间，毫秒
}
```

控制器配置为键值对，其中键为**请求路径**，如`/items`, `/task` 和 `/cpus` 等, 
值只支持填写两个值，分别为 `Object` 和 `Array`，其中 `Object` 代表设定该请求路径的
数据类型为**对象类型**，`Array` 则为 **数组类型**。

默认的配置文件支持配合运行 OC-AE 程序。

##### 多用户模式运行

默认配置文件仅为单用户模式运行，多用户运行则需要将 `enableMultiuser` 置为 `true`，此时以下选项开始生效
```
  "enableMultiuser": false,              // 是否启用多用户
  "userFile": "users.json",              // 用户文件
  "prefixPath": "/user",                 // 请求路径前缀
  "reentTableFile": "reent-table.json",  // 租借表
  "maxReentFreeTime": 604800000          // 最大空闲租借时间，毫秒
```

* userFile: 存储用户信息的文件
* prefixPath: 请求地址前缀，不建议直接使用根路径作为前缀。
* reentTableFile: 租借表，存放用户最后一次有效访问的时间戳
* maxReentFreeTime: 最大租借空闲时间，毫秒，当某一个用户离最后一次的有效访问时间大于该设定时间则将注销该用户。

多用户模式下运行时能够使用 `/apply` 接口申请用户Token，返回格式如下：

```
{
  "code": 200,
  "message": "success",
  "data": "TOKEN"
}
```

在使用该接口后，若申请成功会返回用户Token，并且注册相应的网络地址。

举个例子，在默认配置下调用此接口的返回信息如下 `"data": "token123456"`, 
那么用户需要使用 `http://abc.def/user/token123456` 地址作为后端地址，
`token123456` 作为 Token.

再举个例子，申请成功后，以下请求能够正确的获得结果
```
curl -X GET -H "Content-Type: application/json" -H "ocaetoken: efbedb2f-aad5-41ad-8391-2b98377b3332" -d '[]' -v "http://localhost:8080/user/efbedb2f-aad5-41ad-8391-2b98377b3332/task"
``` 

这下面的其他请求都是返回404
```
curl -X GET -H "Content-Type: application/json" -d '[]' -v "http://localhost:8080/user/efbedb2f-aad5-41ad-8391-2b98377b3332/task"
curl -X GET -H "Content-Type: application/json" -H "ocaetoken: lakhflahsfhaoihoiajg" -d '[]' -v "http://localhost:8080/user/efbedb2f-aad5-41ad-8391-2b98377b3332/task"
``` 

此外，需要注意的是，每天每个IP仅能够申领一次用户Token，以达到一定程度的限制作用。