const headers = {
    "Content-Type": "application/json"
}

function doAction(url, method, body, header) {
    const h = new Headers()
    if (!header) header = {}
    headers.ocaetoken = localStorage.getItem("ocaetoken")

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
    return localStorage.getItem("base-url")
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