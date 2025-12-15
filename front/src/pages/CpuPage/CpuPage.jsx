import {useCallback, useEffect, useState} from "react";
import httpUtil from "../../HttpUtil.jsx";
import AeCpuCard from "../../components/AeCpuCard/AeCpuCard.jsx";
import PropTypes from "prop-types";
import ItemStack from "../../components/itemStack/ItemStack.jsx";
import "./CpuPage.css"
import CommandUtil from "../../commons/CommandUtil.jsx";

function CpuDetail({cpu}) {
    if (cpu == null) return ;
    if (!cpu.cpu) cpu.cpu = {}
    if (!cpu.cpu.activeItems) cpu.cpu.activeItems = []
    if (!cpu.cpu.pendingItems) cpu.cpu.pendingItems = []
    if (!cpu.cpu.storedItems) cpu.cpu.storedItems = []

    return (
        <>
            <h2>{cpu.id} 信息</h2>
            <hr/>
            <div className={"ae-cpu-item-panel"}>
                <div className={"ae-cpu-item-card"}>
                    <h3>正在合成</h3>
                    <hr/>
                    {
                        !cpu.cpu.activeItems || cpu.cpu.activeItems.length === 0 ? <></> :
                        cpu.cpu.activeItems.map((item, idx) => {
                            if (!item) return
                            if (item.amount && item.amount !== 0 || item.size && item.size !== 0)
                                return <ItemStack itemStack={item} key={"1-" + item.label}></ItemStack>
                        })
                    }
                </div>

                <div className={"ae-cpu-item-card"}>
                    <h3>等待合成</h3>
                    <hr/>
                    {
                        !cpu.cpu.pendingItems || cpu.cpu.pendingItems.length === 0 ? <></> :
                        cpu.cpu.pendingItems.map((item, idx) => {
                            if (!item) return
                            if (item.amount && item.amount !== 0 || item.size && item.size !== 0)
                                return <ItemStack itemStack={item} key={"2-" + item.label}></ItemStack>
                        })
                    }
                </div>

                <div className={"ae-cpu-item-card"}>
                    <h3>缓存物品</h3>
                    <hr/>
                    {
                        !cpu.cpu.storedItems || cpu.cpu.storedItems.length === 0 ? <></> :
                        cpu.cpu.storedItems.map((item, idx) => {
                            if (!item) return
                            if (item.amount && item.amount !== 0 || item.size && item.size !== 0)
                                return <ItemStack itemStack={item} key={"3-" + item.label}></ItemStack>
                        })
                    }
                </div>
            </div>
        </>
    )
}

export default function CpuPage() {
    const [cpus, setCpus] = useState([])
    const [cpu, setCpu] = useState({})
    const [lastModified, setLastModified] = useState("")

    useEffect(() => {
        const timer = setInterval(() => {
            if (!CommandUtil.canFetchData()) return;
            httpUtil.get(httpUtil.path.cpus, lastModified && lastModified !== "" ? {"If-Modified-Since": lastModified} : {})
                .then(async resp => {
                    if (resp.status === 200) {
                        setCpus(await resp.json())
                        setLastModified(resp.headers.get("last-modified"))
                    }
                })
        }, 1000)

        return () => {
            clearInterval(timer)
        }
    }, [lastModified]);

    useEffect(() => {
        if (cpu != null) {
            for (const id in cpus) {
                if (cpus[id].id === cpu.id) {
                    setCpu(cpus[id])
                }
            }
        }
    }, [cpus]);

    const onClickCpu = useCallback((cpuId) => {
        for (const id in cpus) {
            if (cpus[id].id === cpuId) {
                setCpu(cpus[id])
            }
        }
    }, [cpus])

    const onDeleteCpu = useCallback((cpu) => {
        if (!cpu || !cpu.id) return
        if (!confirm("是否删除 " + cpu.id + " 信息？")) return;
        httpUtil.delete(httpUtil.path.cpus + "/" + cpu.id).then(async resp => {
            if (resp.status === 200) {
                setCpus((cpus) => {
                    let newOne = []
                    for (const key in cpus) {
                        if (cpus[key] !== cpu.id) {
                            newOne.push(cpus[key])
                        }
                    }
                    return newOne
                })
            }
        })
    }, [])

    const onRefresh = useCallback((cpuId) => {
        CommandUtil.submitCommand("cpuDetail", {
            id: cpuId
        }, async resp => {
            if (resp.status === 200) {

            }
        })
    }, [])

    return (
        <div className={"ae-cpu-page"}>
            <div>
                <button onClick={event => {
                    httpUtil.put(httpUtil.path.task, {
                        "method": "simpleCpusInfo",
                        "data": {}
                    }).then(async resp => {})
                }}>发送更新请求
                </button>
                <button onClick={event => {
                    httpUtil.put(httpUtil.path.task, {
                        "method": "allCpusInfo",
                        "data": {}
                    }).then(async resp => {})
                }}>更新详细信息请求
                </button>
                <button onClick={event => {
                    httpUtil.put(httpUtil.path.task, {
                        "method": "cpuMonitor",
                        "data": {}
                    }).then(async resp => {})
                }}>添加监控
                </button>
                <button onClick={event => {
                    httpUtil.put(httpUtil.path.task, {
                        "method": "cancelMonitor",
                        "data": {"id": "cpuMonitor"}
                    }).then(async resp => {})
                }}>移除监控
                </button>
            </div>

            <br/>
            <div className={"ae-cpu-card-panel"}>
                {
                    !cpus || cpus.length === 0 ? 
                    <span>无CPU, 需要用石英刀给CPU命名, 并且每个CPU的名字必须唯一</span>:
                    cpus.map(cpu => {
                        return <AeCpuCard key={cpu.id} cpu={cpu} onClick={onClickCpu} onRefresh={onRefresh}
                                          onDelete={onDeleteCpu}></AeCpuCard>
                    })
                }
            </div>
            {
                cpu && cpu.id ? <CpuDetail key={cpu.id} cpu={cpu}></CpuDetail> : <></>
            }
        </div>
    )
}

CpuDetail.propTypes = {
    cpu: PropTypes.object
}
