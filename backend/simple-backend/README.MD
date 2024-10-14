### simple-backend

SimpleBackend 是一个带有简单的凭据验证，且为最小化支持 OC-AE 所提出来的后端要求的一个 Spring 实现。

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
  }
}
```

控制器配置为键值对，其中键为**请求路径**，如`/items`, `/task` 和 `/cpus` 等, 
值只支持填写两个值，分别为 `Object` 和 `Array`，其中 `Object` 代表设定该请求路径的
数据类型为**对象类型**，`Array` 则为 **数组类型**。

默认的配置文件支持配合运行 OC-AE 程序。