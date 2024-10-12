import {useState} from "react";
import Config from "../../Config.jsx";

export default function ConfigPage() {
    const [baseUrl, setBaseUrl] = useState(localStorage.getItem("base-url"))
    const [token, setToken] = useState(localStorage.getItem("ocaetoken"))
    const [theme, setTheme] = useState(localStorage.getItem("theme"))

    function saveConfig() {
        if (baseUrl) localStorage.setItem("base-url", baseUrl)
        if (token) localStorage.setItem("ocaetoken", token)
        if (theme && theme !== "") localStorage.setItem("theme", theme)
        alert("成功保存配置到浏览器本地！")
    }

    return (
        <div style={{textAlign: "left", alignItems: "normal"}}>
            <form name={"config-form"}>
                <label htmlFor={"config-base-url"}>基础URL</label>
                <input name={"config-base-url"} placeholder={"基础URL"} defaultValue={baseUrl} type={"url"}
                       onChange={event => setBaseUrl(event.target.value)}/>
                <label htmlFor={"config-token"}>Token</label>
                <input name={"config-token"} placeholder={"Token"} defaultValue={token} type={"password"}
                       onChange={event => setToken(event.target.value)}/>
                <label htmlFor={"config-theme"}>主题</label>
                <select name={"config-theme"} placeholder={"基础URL"} defaultValue={theme}
                       onChange={event => setTheme(event.target.value)}>
                    {
                        Config.theme.map(str => {
                            return <option key={str} value={str}>{str}</option>
                        })
                    }
                </select>
                <br/>
                <br/>
                <button value={"保存"} type={"button"} onClick={event => saveConfig()}>保存</button>
            </form>
        </div>
    )
}