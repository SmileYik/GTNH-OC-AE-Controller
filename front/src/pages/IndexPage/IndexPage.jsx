import "./IndexPage.css"
import PropTypes from "prop-types";

const GITHUB_SVG = (
    <svg height="32" aria-hidden="true" viewBox="0 0 24 24" version="1.1" width="32"
         data-view-component="true"
         className="octicon octicon-mark-github v-align-middle color-fg-default">
        <path
            d="M12.5.75C6.146.75 1 5.896 1 12.25c0 5.089 3.292 9.387 7.863 10.91.575.101.79-.244.79-.546 0-.273-.014-1.178-.014-2.142-2.889.532-3.636-.704-3.866-1.35-.13-.331-.69-1.352-1.18-1.625-.402-.216-.977-.748-.014-.762.906-.014 1.553.834 1.769 1.179 1.035 1.74 2.688 1.25 3.349.948.1-.747.402-1.25.733-1.538-2.559-.287-5.232-1.279-5.232-5.678 0-1.25.445-2.285 1.178-3.09-.115-.288-.517-1.467.115-3.048 0 0 .963-.302 3.163 1.179.92-.259 1.897-.388 2.875-.388.977 0 1.955.13 2.875.388 2.2-1.495 3.162-1.179 3.162-1.179.633 1.581.23 2.76.115 3.048.733.805 1.179 1.825 1.179 3.09 0 4.413-2.688 5.39-5.247 5.678.417.36.776 1.05.776 2.128 0 1.538-.014 2.774-.014 3.162 0 .302.216.662.79.547C20.709 21.637 24 17.324 24 12.25 24 5.896 18.854.75 12.5.75Z"></path>
    </svg>
)

function IconLink({url, iconUrl, title, svg}) {
    return (
        <div className={"icon-link"} title={title}>
            <a href={url} id={"icon-link-icon"}>
                {svg ? svg :
                    <img src={iconUrl} alt={title} title={title}/>
                }
            </a>
            <a href={url}><span>{title}</span></a>
        </div>
    )
}

export default function IndexPage() {
    return (
        <>
            <h1>OC-AE 控制面板</h1>
            <p>
                第一次使用请去设置页面设置好后端地址及Token <br/>
                若设置正确则会自动更新指令框中的结果栏
            </p>
            <div id={"index-author-panel"}>
                <a href={"https://blog.smileyik.eu.org/"} id={"index-author-icon"}>
                    <img src={"https://blog.smileyik.eu.org/common/images/ico_normal.jpg"} alt={"SmileYik"}/>
                </a>
                <div id={"index-author-aside"}>
                    <p>
                        Made by <span>SmileYik</span>
                        <br/>
                        感谢周小姐的鼎力支持
                    </p>

                    <IconLink title={"博客"} iconUrl={"https://blog.smileyik.eu.org/common/images/ico_normal.jpg"} url={"https://blog.smileyik.eu.org/"}></IconLink>
                    <IconLink title={"主页"} svg={GITHUB_SVG} url={"https://github.com/SmileYik/"}></IconLink>
                    <IconLink title={"仓库"} svg={GITHUB_SVG} url={"https://github.com/SmileYik/GTNH-OC-AE-Controller"}></IconLink>
                </div>
                <p>如果喜欢就给个 <a href={"https://github.com/SmileYik/GTNH-OC-AE-Controller"}>⭐Star⭐</a> 吧</p>
            </div>
        </>
    )
}

IconLink.propTypes = {
    url: PropTypes.string,
    title: PropTypes.string,
    iconUrl: PropTypes.string,
    svg: PropTypes.element
}