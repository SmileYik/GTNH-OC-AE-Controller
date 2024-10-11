import PropTypes from 'prop-types';
import itemUtil from "../../ItemUtil.jsx";
import "./ItemStack.css"

function ItemStack({itemStack = null, onCraftRequest}) {
    if (!itemStack) return
    const oriStack = JSON.parse(JSON.stringify(itemStack))
    let air = false
    let item = itemUtil.getItem(itemStack)
    if (item && item.tr === item.name) {
        item.name = itemStack.label
    }
    if (itemStack && itemStack.amount) {
        item = {name: itemStack.name, tr: itemStack.label, maxDurability: 1}
        itemStack.size = itemStack.amount
    } else if (!itemStack) {
        item = {"name":"Air","tr":"空气","tab":"建筑","type":"Block","maxStackSize":64,"maxDurability":1}
        itemStack = {"size": "0", "damage": "0", "name": "Air"}
        air = true
    }
    if (!itemStack.size) itemStack.size = 0
    if (!itemStack.damage) itemStack.damage = 0
    if (!item) {
        item = {"name": itemStack.label,"tr": itemStack.label,"tab":"建筑","type":"Block","maxStackSize":64,"maxDurability":1}
        if (!item.name) {
            item.name = item.tr = itemStack.name
        }
        if (!item.name) {
            item = {"name":"Air","tr":"空气","tab":"建筑","type":"Block","maxStackSize":64,"maxDurability":1}
        }
    }

    let metadata = []
    for (let k in itemStack) {
        metadata.push(
            <div className={"itemInfoLine"}>
                <span title={k}>{k}:</span>
                <span title={itemStack[k] + ""}>{"" + itemStack[k]}</span>
            </div>
        )
    }

    let amount = ""
    if (itemStack.size > 1e9) {
        amount = parseInt(itemStack.size / 1e7 + "") / 100.0 + "G"
    } else if (itemStack.size > 1e6) {
        amount = parseInt(itemStack.size / 1e4 + "") / 100.0 + "M"
    } else if (itemStack.size > 1e3) {
        amount = parseInt(itemStack.size / 1e1 + "") / 100.0 + "K"
    } else {
        amount = itemStack.size
    }
    if (itemStack.amount) {
        amount += "L"
    }

    return (
        <>
            <div className={"itemStack"}>
                <div>
                    {itemStack.isCraftable ? <span className={"item-stack-craftable"} onClick={event => onCraftRequest(oriStack)}>可制造</span> : <></>}
                    <span className={"item-stack-amount"}>
                        <span>x</span>
                        <span title={itemStack.size}>{amount}</span>
                    </span>
                </div>
                <div className="itemIcon">
                    <img src={itemUtil.getLargeIcon(air ? null : itemStack)} alt={item.tr} title={item.tr}/>
                </div>
                <span className={"itemInfoMainName"} title={item.tr}>{item.tr}</span>
                <span className={"itemInfoSubName"} title={item.name}>{item.name}</span>
                <div className={"itemInfo"}>
                    <div className={"itemInfoLine"}>
                        <span>ID:</span>
                        <span title={itemStack.name}>{itemStack.name}</span>
                    </div>
                    <div className={"itemInfoLine"}>
                        <span>损伤值:</span>
                        <span>{itemStack.damage}</span>
                    </div>
                    <hr style={{margin: "0"}}/>
                    {metadata}
                </div>
            </div>
        </>
    )
}

ItemStack.propTypes = {
    itemStack: PropTypes.object,
    onCraftRequest: PropTypes.func
}

export default ItemStack