import "./OCConfigDialog.css"
import PropTypes from 'prop-types';

function getOCConfig(token, baseUrl) {
    return `return {
    sleep = 10,                     -- 两次执行任务时间隔多少秒
    token = "${token}",             -- token
    baseUrl = "${baseUrl}",         -- 基础 url
    path = {                        -- 各项数据路径
        task = "/task",             -- 任务数据所在路径
        cpu = "/cpus",              -- cpu
        essentia = "/essentia",     -- 源质
        fluids = "/fluids",         -- 流体
        items = "/items"            -- 物品
    }
}`
}

function OCConfigDialog({
    token = "未填写",
    baseUrl = "未填写",
    popup = false,
    onClose
}) {
    return (
        <div>
            {
                popup && 
                <div className="pop-panel-mask">
                    <div className="oc-config">
                        <pre>
                            <code>
                                { getOCConfig(token, baseUrl) }
                            </code>
                        </pre>
                        <button value="关闭" onClick={() => onClose()}>关闭</button>
                    </div>
                </div>
            }
        </div>
    )
}

OCConfigDialog.propTypes = {
    token: PropTypes.string,
    baseUrl: PropTypes.string,
    popup: PropTypes.bool,
    onClose: PropTypes.func
}

export default OCConfigDialog
