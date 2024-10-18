import itemDatabase from "./ItemDatabase.json"

function getIcon(obj, prefixPath) {
    if (itemUtil.isItem(obj)) {
        const item = itemUtil.getItem(obj)
        if (item && item["maxDurability"] !== 1) {
            return prefixPath + obj["name"].replaceAll("|", "_").replaceAll(":", "/") + "/1.png"
        }
        return prefixPath + obj["name"].replaceAll("|", "_").replaceAll(":", "/") + "/" + obj["damage"] + ".png"
    }
    return prefixPath + "none.png"
}

const itemUtil = {
    isItem: (obj) => {
        return obj && obj["name"] && obj["damage"] !== null // 防止damage为0时返回false
    },
    getItem: (obj) => {
        if (itemUtil.isItem(obj)) {
            let name = obj["name"]
            if (!itemDatabase[name]) {
                name = name.replaceAll("|", "_")
                if (!itemDatabase[name]) return null
            }
            const damage = (obj["damage"] ? obj["damage"] : 0) + ""
            return itemDatabase[name][damage]
        }
        return null
    },
    getLargeIcon: (obj) => {
        return getIcon(obj, "./images/large/")
    },
    getSmallIcon: (obj) => {
        return getIcon(obj, "./images/small/")
    },
    getFluidIconByName: (name) => {
        return `./images/fluids/${name.replaceAll(":", "_")}.png`
    }
}

export default itemUtil