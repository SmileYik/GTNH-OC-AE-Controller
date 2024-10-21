import PropTypes from 'prop-types';
import itemUtil from "../../ItemUtil.jsx";
import "./ItemStack.css"
import {useEffect, useState} from "react";
import httpUtil from "../../HttpUtil.jsx";

const CRAFTABLE_SVG = (
    <svg t="1728796172948" className="icon" viewBox="0 0 1024 1024" version="1.1" xmlns="http://www.w3.org/2000/svg"
         p-id="1533" width="200" height="200">
        <path
            d="M444.075743 608.642306a17.110065 17.110065 0 0 0-24.202092 0l-170.108645 170.108645a17.112065 17.112065 0 0 0 0 24.202091 17.050065 17.050065 0 0 0 12.102046 5.014019c4.380017 0 8.760033-1.670006 12.102046-5.014019l170.108645-170.108644a17.114065 17.114065 0 0 0-0.002-24.202092zM751.378907 301.341142a17.112065 17.112065 0 0 0-24.202092 0l-28.158106 28.158106a17.112065 17.112065 0 0 0 0 24.202092c3.340013 3.340013 7.722029 5.014019 12.102045 5.014019s8.760033-1.670006 12.102046-5.014019l28.158107-28.158106a17.114065 17.114065 0 0 0-0.002-24.202092z"
            fill="" p-id="1534"></path>
        <path
            d="M992.645821 194.606737c-21.16808-12.006045-46.982178-8.484032-64.238243 8.772034l-51.322195 51.320194-62.358236-16.708063-16.708063-62.358237 51.370194-51.372194c17.222065-17.220065 20.732079-43.156164 8.736033-64.534245-11.980045-21.350081-34.988133-31.450119-58.612222-25.744097-32.000121 7.738029-61.320232 24.144091-84.782321 47.44018-45.368172 45.046171-63.136239 113.026428-46.692177 175.776666l-176.100667 176.100667-230.140872-230.136872 30.570116-30.570116a35.620135 35.620135 0 0 0 9.772037 1.380005c9.058034 0 18.114069-3.448013 25.010095-10.344039l25.818097-25.818098c13.788052-13.790052 13.788052-36.228137 0-50.022189L275.517104 10.340039c-13.790052-13.788052-36.228137-13.788052-50.02219 0L199.678817 36.160137c-9.402036 9.402036-12.380047 22.820086-8.964034 34.782132L157.004655 104.648397c-11.960045-3.418013-25.380096-0.440002-34.782132 8.964033L44.77023 191.064724C14.308114 221.528839 0.136061 265.849007 4.870078 315.861197c4.386017 46.358176 24.624093 90.670344 55.526211 121.57046a17.120065 17.120065 0 0 0 27.852105-5.40602l23.106088-54.348206a17.108065 17.108065 0 0 0-3.648014-18.796071 28.594108 28.594108 0 0 1-8.320031-21.606082c0.406002-8.148031 4.154016-15.520059 10.55004-20.750079 10.59604-8.666033 27.192103-7.464028 38.604146 2.802011a17.114065 17.114065 0 0 0 23.548089-0.624002l13.880053-13.880053 217.230823 217.230823L124.462532 800.783034a107.752408 107.752408 0 0 0-55.42221 29.606112c-20.474078 20.474078-31.75012 47.694181-31.750121 76.646291 0 28.95411 11.276043 56.174213 31.750121 76.64629 21.13208 21.13208 48.890185 31.69612 76.64629 31.69612s55.51421-10.56604 76.64629-31.69612c15.398058-15.398058 25.590097-34.616131 29.698113-55.51621l278.637056-278.637056L743.980879 862.843269l45.940174 96.190365a17.156065 17.156065 0 0 0 3.340013 4.726018l49.880189 49.880189a35.132133 35.132133 0 0 0 25.008094 10.360039c9.448036 0 18.332069-3.680014 25.010095-10.360039l64.546245-64.546245c13.788052-13.790052 13.788052-36.228137 0-50.018189L619.414407 560.780125l175.758666-175.758666c62.864238 17.140065 129.31649-0.226001 175.656666-46.568177 23.120088-23.118088 39.54415-52.020197 47.494179-83.578316 6.024023-23.916091-4.294016-48.134182-25.678097-60.268229zM223.880908 60.362229l25.816098-25.816098a1.136004 1.136004 0 0 1 1.616006 0l77.450294 77.450293a1.144004 1.144004 0 0 1 0 1.616006l-25.814098 25.816098a1.144004 1.144004 0 0 1-1.616006 0L223.880908 61.978235a1.146004 1.146004 0 0 1 0-1.616006z m-12.100046 37.920143l53.248202 53.248202-27.432104 27.432104-53.248201-53.248202 27.432103-27.432104z m-53.840204 186.154706c-22.512085-11.960045-50.25019-10.306039-69.682264 5.594021-13.774052 11.268043-22.180084 27.868106-23.062087 45.540173a62.900238 62.900238 0 0 0 10.62804 38.190144l-8.218031 19.330073c-42.20416-59.612226-36.336138-140.112531 1.372005-177.820673l77.452294-77.452294a1.146004 1.146004 0 0 1 1.616006 0l78.256296 78.258297-68.362259 68.360259z m40.186153 675.040558c-28.91411 28.91811-75.968288 28.92011-104.884398 0-14.010053-14.006053-21.722082-32.632124-21.722082-52.442199 0-19.810075 7.716029-38.434146 21.722082-52.442199 14.458055-14.458055 33.450127-21.688082 52.442199-21.688082s37.984144 7.230027 52.442199 21.688082c14.006053 14.010053 21.722082 32.632124 21.722082 52.442199 0.002 19.810075-7.712029 38.434146-21.722082 52.442199z m52.7882-78.604298c-4.676018-18.950072-14.426055-36.332138-28.582109-50.486192a107.720408 107.720408 0 0 0-50.542191-28.524108l255.602968-255.602968 79.0663 79.066299-255.544968 255.546969z m682.590586 42.40616a1.146004 1.146004 0 0 1 0 1.616006l-64.546244 64.546245a1.086004 1.086004 0 0 1-0.806004 0.334001 1.080004 1.080004 0 0 1-0.808003-0.334001l-47.802181-47.802181-45.940174-96.190365a17.156065 17.156065 0 0 0-3.340012-4.726017L210.164856 280.621063l40.340153-40.340153 683.000588 682.998588z m51.624196-676.766564c-6.440024 25.566097-19.756075 48.988186-38.504146 67.736257-39.63415 39.63415-97.436369 53.116201-150.858572 35.192133a17.114065 17.114065 0 0 0-17.546066 4.124016l-183.010694 183.010693-27.432104-27.432104 108.346411-108.34641a17.112065 17.112065 0 0 0 0-24.202092 17.112065 17.112065 0 0 0-24.202092 0l-108.34641 108.34641-27.432104-27.432103 183.274694-183.274695a17.116065 17.116065 0 0 0 4.174016-17.398066c-17.346066-53.316202-3.506013-112.634427 35.256134-151.122572 19.028072-18.892072 42.788162-32.190122 68.71026-38.460146 12.694048-3.072012 19.066072 6.282024 20.716078 9.222035 3.560013 6.344024 4.618017 15.87206-3.090011 23.580089l-58.356221 58.358221a17.110065 17.110065 0 0 0-4.430017 16.530063l21.822082 81.448308a17.122065 17.122065 0 0 0 12.104046 12.104046l81.448309 21.822083a17.102065 17.102065 0 0 0 16.530063-4.430017l58.308221-58.308221c9.668037-9.668037 20.158076-4.898019 23.144087-3.202012 6.324024 3.588014 12.108046 11.288043 9.374036 22.134084z"
            fill="" p-id="1535"></path>
    </svg>
)

const INFORMATION_SVG = (
    <svg t="1728803793617" className="icon" viewBox="0 0 1024 1024" version="1.1" xmlns="http://www.w3.org/2000/svg"
         p-id="2366" width="200" height="200">
        <path
            d="M512.47 930.498c-111.863 0-217.030-43.561-296.129-122.661-79.099-79.099-122.661-184.265-122.661-296.129 0-111.862 43.562-217.030 122.661-296.129 79.1-79.1 184.267-122.661 296.129-122.661s217.030 43.561 296.129 122.661c79.1 79.1 122.661 184.267 122.661 296.129 0 111.864-43.561 217.030-122.661 296.129-79.099 79.1-184.267 122.661-296.129 122.661zM512.47 131.339c-209.736 0-380.369 170.632-380.369 380.369s170.633 380.369 380.369 380.369c209.736 0 380.37-170.632 380.37-380.369s-170.632-380.369-380.37-380.369zM510.267 759.457c-16.975 0-30.699-13.761-30.699-30.737v-272.79c0-16.976 13.723-30.737 30.699-30.737 16.975 0 30.699 13.761 30.699 30.737v272.79c0 16.975-13.723 30.737-30.699 30.737zM469.135 309.93c0 0 0 0 0 0 0 23.341 18.922 42.263 42.263 42.263 23.341 0 42.263-18.922 42.263-42.263 0 0 0 0 0 0 0 0 0 0 0 0 0-23.341-18.922-42.263-42.263-42.263-23.341 0-42.263 18.922-42.263 42.263 0 0 0 0 0 0z"
            fill="#272636" p-id="2367"></path>
    </svg>
)

const ITEM_STACK_TYPE = {
    FLUID: "fluid",
    ITEM: "item",
    ASPECT: "aspect"
}

function ItemStack({itemStack = null, onCraftRequest}) {
    if (!itemStack) {
        itemStack = {"name": "Air", "label": "空气", "size": 0}
    }

    const oriStack = JSON.parse(JSON.stringify(itemStack))
    let tmpType = ITEM_STACK_TYPE.ITEM
    if (itemStack.aspect) {
        tmpType = ITEM_STACK_TYPE.ASPECT
    } else if (itemStack.amount) {
        tmpType = ITEM_STACK_TYPE.FLUID
        if (itemStack.name.endsWith("essentia")) {
            tmpType = ITEM_STACK_TYPE.ASPECT
            itemStack.aspect = itemStack.name.substring(7, itemStack.name.indexOf("essentia"))
        }
    }

    const [type] = useState(tmpType)
    const [damage, setDamage] = useState(itemStack.damage)
    const [item, setItem] = useState({"name": "Air", "tr": "空气", "tab": "建筑", "type": "Block", "maxStackSize": 64, "maxDurability": 1})

    useEffect(() => {
        let url = "database/" + type + "/"
        switch (type) {
            case ITEM_STACK_TYPE.ITEM:
                url += itemStack.name.toLowerCase().replaceAll(":", ".") + "." + damage + ".json"
                break;
            case ITEM_STACK_TYPE.ASPECT:
                url += itemStack.aspect.toLowerCase() + ".json"
                break;
            case ITEM_STACK_TYPE.FLUID:
                url += itemStack.name.toString() + ".json"
                break;
        }

        httpUtil.doAction(url, "GET")
            .then(async res => {
                if (await res.status === 200) {
                    const target = await res.json()
                    if (type === ITEM_STACK_TYPE.ASPECT) {
                        target.localizedName = target.description
                    }

                    if (itemStack.name === "ae2fc:fluid_drop") {
                        target.localizedName = target.localizedName.substring(3)
                        target.localizedName = itemStack.label.replaceAll("drop of", "").replaceAll("液滴", "") + " " + target.localizedName
                        target.tooltip = target.localizedName
                    }

                    setItem(target)
                } else {
                    if (type === ITEM_STACK_TYPE.ITEM) setDamage(0)
                }
            }).catch(() => {
                if (type === ITEM_STACK_TYPE.ITEM) setDamage(0)
            })
    }, [type, damage, itemStack.name, itemStack.aspect]);

    let metadata = []
    for (let k in oriStack) {
        metadata.push(
            <div className={"itemInfoLine"} key={k}>
                <span title={k}>{k}:</span>
                <span title={oriStack[k] + ""}>{"" + oriStack[k]}</span>
            </div>
        )
    }

    if (itemStack.amount) {
        itemStack.size = itemStack.amount
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
                <div className={"item-stack-tool-bar"}>
                    {itemStack.isCraftable ? <span className={"item-stack-tool-bar-item item-stack-tool-bar-info"} title={"该物品有额外信息"}> {INFORMATION_SVG}</span> : <></>}
                    {itemStack.isCraftable ? <span className={"item-stack-tool-bar-item item-stack-craftable"} title={"可制造"}
                                                   onClick={() => onCraftRequest(oriStack)}>{CRAFTABLE_SVG}</span> : <></>}
                </div>

                <div className="itemIcon">
                    <img loading={"lazy"} src={itemUtil.getIcon(item.imageFilePath)} alt={item.localizedName} title={item.tooltip}/>
                </div>
                <span className={"item-stack-amount"}>
                    <span>x</span>
                    <span title={itemStack.size}>{amount}</span>
                </span>

                <span className={"itemInfoMainName"} title={item.localizedName}>{item.localizedName}</span>
                <span className={"itemInfoSubName"} title={itemStack.label}>{itemStack.label}</span>
                <div className={"itemInfo"}>
                    <div className={"itemInfoLine"}>
                        <span>ID:</span>
                        <span title={itemStack.name}>{itemStack.name}</span>
                    </div>
                    {itemStack && itemStack.damage ? (
                        <div className={"itemInfoLine"}>
                            <span>损伤值:</span>
                            <span>{itemStack.damage}</span>
                        </div>
                    ) : null}
                    {itemStack && itemStack.Temperature ? (
                        <div className={"itemInfoLine"}>
                            <span>温度:</span>
                            <span>{itemStack.Temperature} K</span>
                        </div>
                    ) : null}
                    <hr className={"item-stack-oc-item-hr"}/>
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
