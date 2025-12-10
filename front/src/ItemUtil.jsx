function getIcon(obj, prefixPath) {
    return prefixPath + "none.png"
}

const itemUtil = {
    isItem: (obj) => {
        return obj && obj["name"] && obj["damage"] !== null // 防止damage为0时返回false
    },
    getIcon: (path) => {
        return path ? ("./images/" + path) : "./images/none_large.png"
    },
    getFluidIconByName: (name) => {
        return `./images/fluids/${name.replaceAll(":", "_")}.png`
    }
}

export default itemUtil
