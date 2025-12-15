import HttpUtil from "../HttpUtil.jsx";

function setLastestTimestamp(timestamp) {
    localStorage.setItem("command-timestamp", timestamp)
}

function getLastestTimestamp() {
    return localStorage.getItem("command-timestamp") || Date.now()
}

function clearLastestTimestamp() {
    localStorage.removeItem("command-timestamp")
}

export default {
    submitCommand: (command, bodyData, callback) => {
        if (command == null || command === "") return
        const json = JSON.parse(bodyData)
        const promiss = HttpUtil.put(HttpUtil.path.task, {
            method: command,
            data: json
        })
        if (callback) {
            promiss.then(callback)
        }
        promiss.finally(() => {
            setLastestTimestamp(Date.now())
        })
    },
    canFetchData: () => {
        const currentTimestamp = Date.now()
        const latestTimestamp = getLastestTimestamp()
        // 暂定10秒
        return currentTimestamp - latestTimestamp < 10000
    },
    reset: () => {
        clearLastestTimestamp()
    },
    resetNow: () => {
        setLastestTimestamp(Date.now())
    }
}