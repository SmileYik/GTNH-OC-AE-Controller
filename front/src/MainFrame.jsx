import PropTypes from "prop-types";
import {useCallback, useState} from "react";
import CommandConsole from "./components/CommandConsole/CommandConsole.jsx";
import ItemsPage from "./pages/ItemsPage/ItemsPage.jsx";
import CpuPage from "./pages/CpuPage/CpuPage.jsx";
import FluidPage from "./pages/FluidPage/FluidPage.jsx";
import ConfigPage from "./pages/ConfigPage/ConfigPage.jsx";
import IndexPage from "./pages/IndexPage/IndexPage.jsx";
import "./style.css"
import './MainFrame.css'

const DEFAULT_PAGE = "Index"
const pages = {
    "Index": <IndexPage></IndexPage>,
    "Items": <ItemsPage></ItemsPage>,
    "Fluids": <FluidPage></FluidPage>,
    "Cpus": <CpuPage></CpuPage>,
    "Config": <ConfigPage></ConfigPage>
}

function TabList({onChangeTab, selectedPage}) {
    const tabs = []
    for (const key in pages) {
        tabs.push(<p className={"tab-item " + (selectedPage === key ? "tab-item-selected" : "")} onClick={event=> onChangeTab(key)}>{key}</p>)
    }
    return (
        <div className={"tab-list"}>
            {tabs}
        </div>
    )
}


export default function MainFrame() {
    const [page, setPage] = useState(DEFAULT_PAGE)

    const changePage = useCallback((page) => {
        setPage(page)
    }, [setPage])

    return (
        <div className={"main-page-wrapper"}>
            <TabList onChangeTab={changePage} selectedPage={page}></TabList>
            <div className={"main-page"}>
                {page !== null && page !== "" && pages[page] ? pages[page] : <></>}
            </div>
            <CommandConsole></CommandConsole>
        </div>
    )
}

TabList.propTypes = {
    onChangeTab: PropTypes.func,
    selectedPage: PropTypes.string
}