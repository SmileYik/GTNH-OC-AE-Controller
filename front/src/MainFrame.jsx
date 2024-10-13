import PropTypes from "prop-types";
import {useCallback, useEffect, useState} from "react";
import CommandConsole from "./components/CommandConsole/CommandConsole.jsx";
import ItemsPage from "./pages/ItemsPage/ItemsPage.jsx";
import CpuPage from "./pages/CpuPage/CpuPage.jsx";
import FluidPage from "./pages/FluidPage/FluidPage.jsx";
import ConfigPage from "./pages/ConfigPage/ConfigPage.jsx";
import IndexPage from "./pages/IndexPage/IndexPage.jsx";
import "./commons/style.css"
import './MainFrame.css'

const DEFAULT_PAGE = "Index"
const pages = {
    "Index": <IndexPage></IndexPage>,
    "Items": <ItemsPage></ItemsPage>,
    "Fluids": <FluidPage></FluidPage>,
    "Cpus": <CpuPage></CpuPage>,
    "Config": <ConfigPage></ConfigPage>
}

function TabList({className, onChangeTab, selectedPage}) {
    const tabs = []
    for (const key in pages) {
        tabs.push(<p className={"tab-item " + (selectedPage === key ? "tab-item-selected" : "")} onClick={event=> onChangeTab(key)}>{key}</p>)
    }
    return (
        <div className={className}>
            {tabs}
        </div>
    )
}

export default function MainFrame() {
    const [theme, setTheme] = useState(localStorage.getItem("theme"))
    const [page, setPage] = useState(DEFAULT_PAGE)

    useEffect(() => {
        const timer = setInterval(() => {
            const t = localStorage.getItem("theme")
            console.log(t)
            if (!t) return
            setTheme((old) => {
                if (old !== t) {
                    if (t && t !== "") document.body.className = "body-" + t
                    return t;
                }
                return old
            })
        }, 1000)
        if (theme && theme !== "") document.body.className = "body-" + theme
        else {
            document.body.className = "body-theme-white"
            setTheme("theme-white")
        }

        return () => {
            clearInterval(timer)
        }
    }, [])

    const changePage = useCallback((page) => {
        setPage(page)
    }, [setPage])
    console.log(theme)
    return (
        <div className={"main-page-wrapper"}>
            <TabList className={"tab-list"} onChangeTab={changePage} selectedPage={page}></TabList>
            <div className={"content"}>
                <CommandConsole></CommandConsole>
                <div className={"main-page"}>
                    {page !== null && page !== "" && pages[page] ? pages[page] : <></>}
                </div>
            </div>
        </div>
    )
}

TabList.propTypes = {
    onChangeTab: PropTypes.func,
    selectedPage: PropTypes.string,
    className: PropTypes.string
}