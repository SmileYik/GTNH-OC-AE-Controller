export default {
    tasks: {
        "none": {
            method: "",
            data: ""
        },
        "搜索物品": {
            method: "refreshStorage",
            data: "{\n  \n}"
        },
        "制造物品": {
            method: "requestItem",
            data: JSON.stringify({
                filter: {
                    name: "",
                    damage: ""
                },
                amount: "",
                cpuName: ""
            }, null, 2)
        },
        "查看监控器": {
            method: "monitors",
            data: "{\n}"
        },
        "取消监控器": {
            method: "cancelMonitor",
            data: JSON.stringify({
                id: ""
            }, null, 2)
        },
        "搜索流体库存": {
            method: "refreshFluidStorage",
            data: "{}"
        }
    },
    theme: [
        "theme-blue",
        "theme-white"
    ],
    shareServer: {
        "": "手动输入",
        "本地测试服务器": "http://localhost:60081/apply",
        "502y 的服务器": "http://111.231.23.21:60081/apply"
    }
}