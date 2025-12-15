import {useCallback, useEffect, useState, useRef, useMemo} from "react";
import httpUtil from "../../HttpUtil.jsx";
import ItemStack from "../../components/itemStack/ItemStack.jsx";
import CommandUtil from "../../commons/CommandUtil.jsx";
import PageList from "../../components/PageList/PageList.jsx";
import useResizeObserver from "../../components/useResizeObserver.jsx";

export default function EssentiaPage() {
    const [items, setItems] = useState([])
    const [lastModified, setLastModified] = useState("")

    const onCraftRequest = useCallback((itemStack) => {
        if (!itemStack || !itemStack.isCraftable) return;
        const numberString = prompt("可制造" + itemStack.label + "，请输入要制造的数量: ","0");
        const number = parseInt(numberString)
        if (number + "" !== numberString || number === 0 || isNaN(number)) return;
        CommandUtil.submitCommand("requestItem", {
            filter: {
                name: itemStack.name,
                aspect: itemStack.aspect
            },
            amount: number
        }, async resp => {
            if (resp.status === 200) {
                alert("制造 " + itemStack.label + " 的请求已经发送！")
            }
        })
    }, [])

    useEffect(() => {
        const timer = setInterval(() => {
            if (!CommandUtil.canFetchData()) return;
            httpUtil.get(httpUtil.path.essentia, lastModified && lastModified !== "" ? {"If-Modified-Since": lastModified} : {})
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

    const contentRef = useRef(null);
    const contentRect = useResizeObserver(contentRef);
    const defaultPageSize = useMemo(() => {
        return (Math.floor(contentRect.width / 138)) * 2;
    }, [contentRect]);
    const [queryParams, setQueryParams] = useState({ 
        label: '', 
        name: '', 
        damage: '' 
    });
    const [queryList, setQueryList] = useState([]);

    const renderItemStack = useCallback((item, index) => {
        return (<ItemStack itemStack={item} onCraftRequest={onCraftRequest} key={item.name + ":" + item.damage + ":" + item.label + ":" + item.size + ":" + index}></ItemStack>)
    }, [])

    const buildQueryList = useCallback(() => {
        const list = [];
        if (queryParams.name && queryParams.name !== '') {
            list.push((data) => data.filter(elem => elem.name && elem.name.toLowerCase().indexOf(queryParams.name.toLowerCase()) >= 0))
        }
        if (queryParams.label && queryParams.label !== '') {
            list.push(data => data.filter(elem => elem.label && elem.label.toLowerCase().indexOf(queryParams.label.toLowerCase()) >= 0));
        }
        if (queryParams.damage && queryParams.damage !== '') {
            list.push(data => data.filter(elem => elem.damage && elem.damage == queryParams.damage));
        }
        setQueryList(list)
    }, [queryParams, queryList])

    const renderQueryHeader = useCallback(() => {
        return (
            <div className="page-list-query-header">
                <label>
                    <span>流体类型:</span> 
                    <input value={queryParams.name} 
                           onChange={e => setQueryParams(params => {return {...params, name: e.target.value}})}></input>
                </label>

                <label>
                    <span>流体名称:</span> 
                    <input value={queryParams.label} 
                           onChange={e => setQueryParams(params => {return {...params, label: e.target.value}})}></input>
                </label>

                <label>
                    <span>流体损伤:</span> 
                    <input value={queryParams.damage} 
                           onChange={e => setQueryParams(params => {return {...params, damage: e.target.value}})}></input>
                </label>

                <span>
                    <button onClick={buildQueryList}>搜索</button>
                    <button onClick={() => {
                        setQueryParams({
                            name: '',
                            label: '',
                            damage: ''
                        })
                        setTimeout(() => {
                            buildQueryList()
                        }, 100)
                    }}>重置</button>
                </span>
            </div>
        )
    })

    return (
        <>
            <div ref={contentRef}>
                <button onClick={event => {
                    httpUtil.put(httpUtil.path.essentia, {
                        "result": []
                    }).then(async resp => {})
                }}>
                    清理所有源质
                </button>
                <button onClick={event => {
                    httpUtil.put(httpUtil.path.task, {
                        "method": "refreshEssentiaStorage",
                        "data": {}
                    }).then(async resp => {})
                }}>
                    搜寻源质
                </button>
            </div>

            <br/>
            {
                !items || items.length === 0 ?
                <span>无源质</span> :
                <PageList data={items} 
                          defaultPageSize={defaultPageSize}
                          onRender={renderItemStack} 
                          onHeadRender={renderQueryHeader} 
                          querys={queryList}
                ></PageList>
            }
        </>
    )
}
