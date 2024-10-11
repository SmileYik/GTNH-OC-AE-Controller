import {useCallback, useEffect, useState} from "react";
import httpUtil from "../../HttpUtil.jsx";
import AeCpuCard from "../../components/AeCpuCard/AeCpuCard.jsx";
import PropTypes from "prop-types";
import ItemStack from "../../components/itemStack/ItemStack.jsx";
import "./CpuPage.css"

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
                        cpu.cpu.activeItems.map(item => {
                            if (!item) return
                            if (item.amount && item.amount !== 0 || item.size && item.size !== 0)
                                return <ItemStack itemStack={item} key={item}></ItemStack>
                        })
                    }
                </div>

                <div className={"ae-cpu-item-card"}>
                    <h3>等待合成</h3>
                    <hr/>
                    {
                        cpu.cpu.pendingItems.map(item => {
                            if (!item) return
                            if (item.amount && item.amount !== 0 || item.size && item.size !== 0)
                                return <ItemStack itemStack={item} key={item}></ItemStack>
                        })
                    }
                </div>

                <div className={"ae-cpu-item-card"}>
                    <h3>缓存物品</h3>
                    <hr/>
                    {
                        cpu.cpu.storedItems.map(item => {
                            if (!item) return
                            if (item.amount && item.amount !== 0 || item.size && item.size !== 0)
                                return <ItemStack itemStack={item} key={item}></ItemStack>
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

    useEffect(() => {
        const timer = setInterval(() => {
            httpUtil.get(httpUtil.path.cpus)
                .then(async resp => {
                    if (resp.status === 200) {
                        setCpus(await resp.json())
                    }
                })
        }, 1000)

        return () => {
            clearInterval(timer)
        }
    }, []);

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
        httpUtil.put(httpUtil.path.task, {
            "method": "cpuDetail",
            "data": {
                "id": cpuId
            }
        }).then(async resp => {
            if (resp.status === 200) {

            }
        })
    }, [])

    return (
        <>
            <button onClick={event => {
                httpUtil.put(httpUtil.path.task, {
                    "method": "simpleCpusInfo",
                    "data": {}
                }).then(async resp => {
                })
            }}>发送更新请求
            </button>
            <button onClick={event => {
                httpUtil.put(httpUtil.path.task, {
                    "method": "allCpusInfo",
                    "data": {}
                }).then(async resp => {
                })
            }}>更新详细信息请求
            </button>
            <button onClick={event => {
                httpUtil.put(httpUtil.path.task, {
                    "method": "cpuMonitor",
                    "data": {}
                }).then(async resp => {
                })
            }}>添加监控
            </button>
            <button onClick={event => {
                httpUtil.put(httpUtil.path.task, {
                    "method": "cancelMonitor",
                    "data": {"id": "cpuMonitor"}
                }).then(async resp => {
                })
            }}>移除监控
            </button>
            <div className={"ae-cpu-card-panel"}>
                {
                    cpus.map(cpu => {
                        return <AeCpuCard key={Math.random()} cpu={cpu} onClick={onClickCpu} onRefresh={onRefresh} onDelete={onDeleteCpu}></AeCpuCard>
                    })
                }
            </div>
            {
                cpu && cpu.id ? <CpuDetail cpu={cpu}></CpuDetail> : <></>
            }
        </>
    )
}

CpuDetail.propTypes = {
    cpu: PropTypes.object
}
