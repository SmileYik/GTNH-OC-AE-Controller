const headers = {
    "Content-Type": "application/json"
}

function doAction(url, method, body, header) {
    const h = new Headers()
    if (!header) header = {}
    let ocaetoken = localStorage.getItem("ocaetoken")
    if (!ocaetoken) {
        ocaetoken = prompt("未在本地查询到请求密钥，请输入密钥")
        if (ocaetoken) {
            localStorage.setItem("ocaetoken", ocaetoken)
        }
    }
    headers.ocaetoken = ocaetoken

    for (const key in header) h.append(key, header[key])
    for (const key in headers) h.append(key, headers[key])
    if (body != null && typeof body !== "string") {
        body = JSON.stringify(body)
    }

    return fetch(url, {
        method: method,
        headers: h,
        body: body,
        mode: "cors"
    })
}

function getBaseUrl() {
    let url = localStorage.getItem("base-url")
    if (url) return url
    url = prompt("未在本地查询到基础URL, 请输入基础URL. \n请注意需要在后端添加跨站访问许可。")
    if (url) {
        localStorage.setItem("base-url", url)
    }
    return url
}

export default {
    path: {
        task: "/task",
        items: "/items",
        cpus: "/cpus",
        fluids: "/fluids"
    },
    addGlobalHeader: (key, val) => {
        headers[key] = val
    },
    put: (path, body, header) => {
        return doAction(getBaseUrl() + path, "PUT", body, header)
    },
    post: (path, body, header) => {
        return doAction(getBaseUrl() + path, "POST", body, header)
    },
    delete: (path, header) => {
        return doAction(getBaseUrl() + path, "DELETE", null, header)
    },
    get: (path, header) => {
        return doAction(getBaseUrl() + path, "GET", null, header)
    },
}