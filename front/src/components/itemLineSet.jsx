const inputLineNumber = (defaultLineCount) => {
    const numberString = prompt("请输入要显示的物品行数: ", defaultLineCount + "");
    const number = parseInt(numberString)
    if (number + "" !== numberString || number === 0 || isNaN(number)) number = defaultLineCount;
    return number
}

const ItemLineSetButton = ({
    onLineChanged,
    currentLine
}) => {
    return (
        <button onClick={() => {
            onLineChanged(inputLineNumber(currentLine))
        }}>设置显示行数</button>
    )
}

export default ItemLineSetButton;