import {useState} from "react";

export default function ConfigPage() {
    const [baseUrl, setBaseUrl] = useState(localStorage.getItem("base-url"))
    const [token, setToken] = useState(localStorage.getItem("ocaetoken"))

    function saveConfig() {
        localStorage.setItem("base-url", baseUrl)
        localStorage.setItem("ocaetoken", token)
        alert("成功保存配置到浏览器本地！")
    }

    return (
        <div style={{textAlign: "left", alignItems: "normal"}}>
            <form name={"config-form"}>
                <label htmlFor={"config-base-url"}>基础URL</label>
                <input name={"config-base-url"} placeholder={"基础URL"} defaultValue={baseUrl} type={"url"} onChange={event => setBaseUrl(event.target.value)}/>
                <label htmlFor={"config-token"}>Token</label>
                <input name={"config-token"} placeholder={"Token"} defaultValue={token} type={"password"} onChange={event => setToken(event.target.value)}/>
                <br/>
                <br/>
                <button value={"保存"} type={"button"} onClick={event => saveConfig()} >保存</button>
            </form>
        </div>
    )
}