import {useCallback, useEffect, useState} from "react";
import httpUtil from "../../HttpUtil.jsx";
import ItemStack from "../../components/itemStack/ItemStack.jsx";

export default function FluidPage() {
    const [items, setItems] = useState([])
    const [lastModified, setLastModified] = useState("")

    const onCraftRequest = useCallback((itemStack) => {
        if (!itemStack || !itemStack.isCraftable) return;
        const numberString = prompt("可制造" + itemStack.label + "，请输入要制造的数量: ","0");
        const number = parseInt(numberString)
        console.log(number, number + "" === numberString)
        if (number + "" !== numberString || number === 0 || isNaN(number)) return;

        httpUtil.put(httpUtil.path.task, {
            "method": "requestItem",
            "data": {
                filter: {
                    name: itemStack.name
                },
                amount: number
            }
        })
        .then(async resp => {
            if (resp.status === 200) {
                alert("制造 " + itemStack.label + " 的请求已经发送！")
            }
        })
    }, [])

    useEffect(() => {
        const timer = setInterval(() => {
            httpUtil.get(httpUtil.path.fluids, lastModified && lastModified !== "" ? {"If-Modified-Since": lastModified} : {})
                .then(async response => {
                    if (response.status === 200) {
                        const r = await response.json();
                        if (r.result) setItems(r.result)
                        setLastModified(response.headers.get("last-modified"))
                    }
                })
        }, 1000)
        return () => {
            clearInterval(timer)
        }
    }, [lastModified]);

    return (
        <>
            <div>
                <button onClick={event => {
                    httpUtil.put(httpUtil.path.fluids, {
                        "result": []
                    }).then(async resp => {})
                }}>
                    清理所有流体
                </button>
                <button onClick={event => {
                    httpUtil.put(httpUtil.path.task, {
                        "method": "refreshFluidStorage",
                        "data": {}
                    }).then(async resp => {})
                }}>
                    搜寻流体
                </button>
            </div>

            <br/>
            {
                items || items.length === 0 ?
                <span>无流体</span> :
                items.map(item => {
                    return (<ItemStack itemStack={item} onCraftRequest={onCraftRequest} key={item.name + ":" + item.damage + item.label}></ItemStack>)
                })
            }
        </>
    )
}
