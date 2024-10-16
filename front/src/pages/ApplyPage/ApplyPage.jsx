import {useEffect, useState} from "react";
import Config from "../../Config.jsx";
import httpUtil from "../../HttpUtil.jsx";
import PropTypes from "prop-types";

function ShareTokenCard({url, token}) {
    return (
        <>
            <label htmlFor={"input-share-token"}>Token</label>
            <input id="input-share-token" type={"text"} value={token} contentEditable={false}/>
            <label htmlFor={"input-share-base-url"}>URL</label>
            <input id="input-share-base-url" type={"url"} value={url} contentEditable={false}/>
        </>
    )
}

function ApplyResult({result}) {
    if (result === null) {
        return <></>
    }
    return (
        <div className={"apply-result"}>
            <h2>申领结果</h2>
            {
                result.data ?
                    (
                        <ShareTokenCard url={result.data.url} token={result.data.token}></ShareTokenCard>
                    ) :
                    (
                        <p>{result.message}</p>
                    )
            }
        </div>
    )
}

export default function ApplyPage() {
    const [shareServer, setShareServer] = useState("")
    const [url, setUrl] = useState("")
    const [apply, setApply] = useState(false)
    const [result, setResult] = useState(null)

    const [prevUrl] = useState(localStorage.getItem("shared-url"))
    const [prevToken] = useState(localStorage.getItem("shared-token"))

    useEffect(() => {
        if (!apply) return
        let u = url
        if (shareServer !== "") {
            u = Config.shareServer[shareServer]
        }

        httpUtil.doAction(u, "GET", null, null)
            .then(async res => {
                if (await res.status === 200) {
                    const result = await res.json()
                    if (result.data && result.data.url) {
                        if (!result.data.url.startsWith("http")) {
                            result.data.url = u.substring(0, u.length - 6) + result.data.url
                        }
                        localStorage.setItem("shared-url", result.data.url)
                    }
                    if (result.data && result.data.token) {
                        localStorage.setItem("shared-token", result.data.token)
                    }
                    setResult(result)
                } else {
                    setApply(false)
                    setResult(null)
                }
            })
            .catch(() => {
                setApply(false)
                setResult(null)
                alert("申请失败，请检查链接和网络是否正常")
            })

    }, [apply])

    const servers = []
    for (const key in Config.shareServer) {
        servers.push(
            <option value={key}>{key === "" ? "手动输入" : key}</option>
        )
    }

    return (
        <div className={"apply-page"}>
            <label htmlFor={"select-share-server"}>分享服务器</label>
            <select inputMode={"url"} id={"select-share-server"} defaultValue={shareServer}
                    onChange={event => setShareServer(event.target.value)}>
                {servers}
            </select>

            <label htmlFor={"select-share-server"}>URL</label>
            <input id={"input-share-server"}
                   disabled={shareServer !== "" && shareServer !== "手动输入"}
                   type={"url"} placeholder={"在此手动输入分享地址"}
                   defaultValue={url} onChange={event => setUrl(event.target.value)}/>
            <div>
                {
                    // https 混用 http 接口警告
                    shareServer !== "" && Config.shareServer[shareServer].startsWith("https") ||
                    document.URL.startsWith("http:") ||
                    shareServer === "" && (url === "" || url && url.startsWith("https")) ? <></> :
                        <span className={"config-base-url-is-http"}>
                            您想使用 HTTP 接口，但访问本站的方式为 HTTPS，这将会导致访问接口数据失败。您需要切换成 HTTP 方式访问本站，以防止接口调用失败。
                            您可能需要去手动关闭浏览器的强制 HTTPS 模式。
                            <a href={document.URL.replace("https:", "http:")}> 以 HTTP 方式访问本站 </a>。
                        </span>
                }
            </div>


            <br/>
            <button disabled={apply} onClick={event => setApply(true)}>申领</button>
            <br/>

            <ApplyResult result={result}></ApplyResult>

            <div className={"pre-shared-token"}>
                <h2>上一次申领的 Token</h2>
                {
                    prevToken && prevUrl ? <ShareTokenCard url={prevUrl} token={prevToken}></ShareTokenCard> :
                        <p>好像没有申领过哦</p>
                }
            </div>
        </div>
    )
}

ApplyResult.propTypes = {
    result: PropTypes.object
}

ShareTokenCard.propTypes = {
    url: PropTypes.string,
    token: PropTypes.string
}