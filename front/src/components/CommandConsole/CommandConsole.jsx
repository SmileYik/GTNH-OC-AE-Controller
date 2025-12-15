import {useCallback, useEffect, useState} from "react";
import httpUtil from "../../HttpUtil.jsx";
import CommandUtil from "../../commons/CommandUtil.jsx";
import "./CommandConsole.css"
import Config from "../../Config.jsx";
import PropTypes from "prop-types";

function CommandArea({fixed, setFixed}) {

    let commandOption = []
    for (const key in Config.tasks) {
        if (key === "none") continue
        commandOption.push(<option value={key} key={key}>{key}</option>)
    }

    const [command, setCommand] = useState("")
    const [bodyData, setBodyData] = useState("")


    return (
        <>
            <div className={"command-area"}>
                <div className={"command-area-line command-area-line-1"}>
                    <span><input type={"checkbox"} checked={fixed} onChange={event => setFixed(event.target.checked)}></input>指令:</span>
                    <select onChange={event => {
                        setCommand(Config.tasks[event.target.value].method)
                        setBodyData(Config.tasks[event.target.value].data)
                    }}>
                        <option value={"none"}></option>
                        {commandOption}
                    </select>
                    {/*<input placeholder={"在这里输入指令"} defaultValue={command}*/}
                    {/*       onChange={event => setCommand(event.target.value)}/>*/}
                </div>
                <div className={"command-area-line command-area-line-2"}>
                    <span>参数:</span>
                    <textarea placeholder={"在这里输入参数"} defaultValue={bodyData}
                              onChange={event => setBodyData(event.target.value)}/>
                </div>
            </div>
            <span className={"command-area-submit-btn"}
                  title="发送指令给游戏"
                  onClick={() => CommandUtil.submitCommand(command, bodyData)}>提交指令</span>
            <span className={"command-area-submit-btn"}
                  title="一段时间没有操作会终止与服务器的交互, 点击这个按钮可以重新开始与服务器交互"
                  onClick={() => CommandUtil.resetNow()}>刷新状态</span>
        </>
    )
}

function CommandStatus() {
    const [commandStatus, setCommandStatus] = useState("")
    const [lastModified, setLastModified] = useState("")
    const [refreshStatus, setRefreshStatus] = useState(true)

    useEffect(() => {
        const timer = setInterval(() => {
            const status = CommandUtil.canFetchData()
            setRefreshStatus((old) => {
                if (old !== status) {
                    return status
                }
                return old
            })
            if (!status) return;
            httpUtil.get(httpUtil.path.task, lastModified && lastModified !== "" ? {"If-Modified-Since": lastModified} : {})
                .then(async response => {
                    if (response.status === 200) {
                        setCommandStatus(await response.text())
                        setLastModified(response.headers.get("last-modified"))
                    }
                })
                .catch((error) => {
                    if (typeof error === "string") setCommandStatus(error)
                })
        }, 1000)

        return () => {
            clearInterval(timer)
        }
    }, [lastModified]);

    return (
        <textarea contentEditable={false} value={
            (refreshStatus ? "" : "停止向服务器同步数据, 点击刷新状态按钮重新开启数据同步\n") + (commandStatus ? commandStatus : "")
        } onChange={() => {}}/>
    )
}

export default function CommandConsole() {
    const [fixed, setFixed] = useState(true)
    const onSetFixed = useCallback((fixed) => {
        setFixed(fixed)
    })

    return (
        <div className={"command-console " + (fixed ? "command-console-fixed" : "")}>
            <CommandArea fixed={fixed} setFixed={onSetFixed}></CommandArea>

            <div className={"command-status-area"}>
                <CommandStatus/>
            </div>
        </div>
    )
}

CommandArea.propTypes = {
    fixed: PropTypes.bool,
    setFixed: PropTypes.func
}