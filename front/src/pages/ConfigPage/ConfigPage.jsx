import {useState} from "react";
import Config from "../../Config.jsx";
import "./ConfigPage.css"
import OCConfigDialog from "../../components/OCConfigDialog/OCConfigDialog.jsx";

export default function ConfigPage() {
    const [baseUrl, setBaseUrl] = useState(localStorage.getItem("base-url"))
    const [hideBaseUrl, setHideBaseUrl] = useState(true)
    const [token, setToken] = useState(localStorage.getItem("ocaetoken"))
    const [theme, setTheme] = useState(localStorage.getItem("theme"))
    const [displayOCConfig, setDisplayOCConfig] = useState(false)

    function saveConfig() {
        if (baseUrl) localStorage.setItem("base-url", baseUrl)
        if (token) localStorage.setItem("ocaetoken", token)
        if (theme && theme !== "") localStorage.setItem("theme", theme)
        alert("成功保存配置到浏览器本地！")
    }

    return (
        <div style={{textAlign: "left", alignItems: "normal"}}>
            <form name="config-form" className="config-form">
                <label htmlFor={"config-base-url"}>
                    基础URL
                    <input type={"checkbox"} checked={hideBaseUrl}
                           onChange={(event) => setHideBaseUrl(event.target.checked)}/>
                </label>
                <input name={"config-base-url"} placeholder={"基础URL"} defaultValue={baseUrl} type={ hideBaseUrl ? "password" : "url"}
                       onChange={event => setBaseUrl(event.target.value)}/>
                <div>
                    {
                        // https 混用 http 接口警告
                        baseUrl == null || baseUrl.startsWith("https") || document.URL.startsWith("http:") ? <></> :
                        <span className={"config-base-url-is-http"}>
                            您想使用 HTTP 接口，但访问本站的方式为 HTTPS，这将会导致访问接口数据失败。您需要切换成 HTTP 方式访问本站，以防止接口调用失败。
                            您可能需要去手动关闭浏览器的强制 HTTPS 模式。
                            <a href={document.URL.replace("https:", "http:")}> 以 HTTP 方式访问本站 </a>。
                        </span>
                    }
                </div>
                <label htmlFor={"config-token"}>Token</label>
                <input name={"config-token"} placeholder={"Token"} defaultValue={token} type={"password"}
                       onChange={event => setToken(event.target.value)}/>
                <label htmlFor={"config-theme"}>主题</label>
                <select name={"config-theme"} defaultValue={theme}
                       onChange={event => setTheme(event.target.value)}>
                    {
                        Config.theme.map(str => {
                            return <option key={str} value={str}>{str}</option>
                        })
                    }
                </select>
                <br/>
                <br/>
                <div style={{textAlign: "center"}}>
                    <button value="保存" type="button" onClick={() => saveConfig()}>保存</button>
                    <button value="查看OC配置" type="button" onClick={() => setDisplayOCConfig(true)}>查看OC配置</button>
                </div>
                <OCConfigDialog popup={displayOCConfig} token={token} baseUrl={baseUrl} onClose={() => setDisplayOCConfig(false)}></OCConfigDialog>
            </form>
        </div>
    )
}