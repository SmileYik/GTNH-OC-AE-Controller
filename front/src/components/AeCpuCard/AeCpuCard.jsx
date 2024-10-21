import PropTypes from "prop-types";
import "./AeCpuCard.css"

function AeCpuCardLine({lineKey, value}) {
    return (
        <div className={"ae-cpu-card-line"}>
            <span>{lineKey}</span>
            <span>{value}</span>
        </div>
    )
}

export default function AeCpuCard({onClick, cpu, onRefresh, onDelete}) {
    return (
        <div className={"ae-cpu-card " + (cpu.busy ? "ae-cpu-card-busy" : "") } onClick={event => onClick(cpu.id)}>
            <div className={"ae-cpu-card-tool-bar"}>
                <span title={"删除"} className={"ae-cpu-card-tool-bar-delete"} onClick={event => onDelete(cpu)}>X</span>
            </div>
            <h2 className={"ae-cpu-card-name"}>{cpu.id}</h2>
            <AeCpuCardLine lineKey="容量:" value={(cpu.storage / 1024) + "K"}></AeCpuCardLine>
            <AeCpuCardLine lineKey="并行:" value={cpu.coprocessors}></AeCpuCardLine>
            <h3 className={"ae-cpu-card-status"}>{cpu.busy ? "运行中" : "空闲中"}</h3>
            <span className={"ae-cpu-card-refresh"} onClick={event => onRefresh(cpu.id)}>刷新状态</span>
        </div>
    )
}

AeCpuCardLine.propTypes = {
    lineKey: PropTypes.string,
    value: PropTypes.any
}

AeCpuCard.propTypes = {
    onClick: PropTypes.func,
    cpu: PropTypes.object,
    onRefresh: PropTypes.func,
    onDelete: PropTypes.func
}
