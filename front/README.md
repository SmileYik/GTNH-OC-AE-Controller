# OC-AE 控制面板

这是一个简单的前端实现，拥有基本的功能。该前端中使用的物品图片与物品数据库都由 [IRR](https://github.com/0999312/Item-Render-Rebirth) 导出。

### 运行

```
yarn run dev
```

### 编译

```
yarn run build
```

### 在线访问控制面板

在线访问地址：https://blog.smileyik.eu.org/oc-ae/

未绑定后端，在首次访问页面时会询问后端地址以及token。
所有数据将会保存在你的浏览器本地，不会存入任何云端。

### 添加新的功能

#### Config.jsx - 配置指令模板

Config.jsx 中存放着执行指令的模板，执行的指令应该与 oc 端相同，只有这样 oc 端才能识别指令。

配置格式如下。
```
tasks: {
    "指令描述": {
        method: "oc端方法名",
        data: "参数"
    }
}
```

#### MainFrame.jsx - 配置页面

在 MainFrame.jsx 的顶层有如下表：
```
const pages = {
    "TestPage": <TestPage></TestPage>,
    "Items": <ItemsPage></ItemsPage>,
    "Fluids": <FluidPage></FluidPage>,
    "Cpus": <CpuPage></CpuPage>
}
```

修改该表可以添加或删除相应的导航与页面。


#### ItemDatabase.json - 配置物品数据库

该文件由 [IRR](https://github.com/0999312/Item-Render-Rebirth) 导出。