import {useEffect, useState} from "react";
import httpUtil from "../../HttpUtil.jsx";
import "./CommandConsole.css"
import Config from "../../Config.jsx";

function CommandArea() {
    function submitCommand(command, bodyData) {
        if (command == null || command === "") return
        const json = JSON.parse(bodyData)
        httpUtil.put(httpUtil.path.task, {
            method: command,
            data: json
        }).then(val => {

        })
    }

    let commandOption = []
    for (const key in Config.tasks) {
        if (key === "none") continue
        commandOption.push(<option value={key}>{key}</option>)
    }

    const [command, setCommand] = useState("")
    const [bodyData, setBodyData] = useState("")

    return (
        <>
            <div className={"command-area-line command-area-line-1"}>
                <span>指令:</span>
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
            <span className={"command-area-submit-btn"} onClick={event => submitCommand(command, bodyData)}>提交指令</span>
        </>
    )
}

function CommandStatus() {
    const [commandStatus, setCommandStatus] = useState("")
    useEffect(() => {
        const timer = setInterval(() => {
            httpUtil.get(httpUtil.path.task, null)
                .then(async response => {
                    if (response.status === 200) return setCommandStatus(await response.text())
                })
        }, 1000)

        return () => {
            clearInterval(timer)
        }
    }, []);

    return (
        <textarea contentEditable={false} value={commandStatus ? commandStatus : ""}/>
    )
}

export default function CommandConsole() {
    return (
        <div className={"command-console"}>
            <div className={"command-area"}>
                <CommandArea></CommandArea>
            </div>
            <div className={"command-status-area"}>
                <CommandStatus/>
            </div>
        </div>
    )
}