import PropTypes from "prop-types";
import { Fragment, useEffect, useMemo } from "react";
import { useState } from "react";
import "./PageList.css"
import useResizeObserver from "../useResizeObserver";
import { useRef } from "react";

function PageButtons({
    currentPage,
    maxPage,
    onPageChange,
    leftSize,
    rightSize
}) {
    let begin = Math.max(1, currentPage - leftSize);
    let end = Math.min(maxPage, currentPage + rightSize);
    while (end - begin !== leftSize + rightSize && begin !== 1) {
        begin -= 1; 
    }
    while (end - begin !== leftSize + rightSize && end !== maxPage) {
        end += 1; 
    }

    return (
        <span className="page-list-page-buttons">
            {
                leftSize > 1 && begin > 2 &&
                (
                    <Fragment>
                        <button className="page-list-page-button" onClick={() => onPageChange(1)}>1</button>
                        <button className="page-list-page-button page-list-page-button-dot" >•••</button>
                    </Fragment>
                )
            }
            {
                Array.from({ length: end - begin + 1 }, (_, i) => i).map(idx => {
                    return (<button className={
                        "page-list-page-button" +
                        (begin + idx === currentPage ? " page-list-page-button-current" : "")
                    } key={begin + idx} onClick={() => onPageChange(begin + idx)}>{begin + idx}</button>)
                })
            }
            {
                rightSize > 1 && end < maxPage - 1 &&
                (
                    <Fragment>
                        <button className="page-list-page-button page-list-page-button-dot" >•••</button>
                        <button className="page-list-page-button" onClick={() => onPageChange(maxPage)}>{maxPage}</button>
                    </Fragment>
                )
            }
        </span>
    )
}

/**
 * 
 * @param {object} props 
 * @param {array} props.data
 * @param {array} props.querys
 * @returns 
 */
function PageList({
    data,
    onRender,
    onHeadRender = () => {
        return;
    },
    querys = [],
    defaultPageSize = 20
}) {
    const [currentPage, setCurrentPage] = useState(1);
    const [pageSize, setPageSize] = useState(defaultPageSize);
    const footRef = useRef(null);
    const footRect = useResizeObserver(footRef);
    const filteredData = useMemo(() => {
        let array = [...data]
        for (const query of querys) {
            array = query(array)            
        }
        setCurrentPage(1)
        return array
    }, [data, querys]);
    const pageButtonCounts = useMemo(() => {
        console.log(footRect.width)
        const count = Math.floor(footRect.width / 12 / 32)
        return Math.min(count, 3)
    }, [footRect])

    useEffect(() => {
        setPageSize(defaultPageSize)
    }, [defaultPageSize])
    const maxPageSize = useMemo(() => {
        const len = filteredData.length
        return Math.floor(len / pageSize) + (len % pageSize === 0 ? 0 : 1)
    }, [pageSize, filteredData])
    const pageIndexBegin = useMemo(() => {
        return (currentPage - 1) * pageSize;
    }, [pageSize, currentPage])
    const pageIndexEnd = useMemo(() => {
        return currentPage * pageSize;
    }, [pageSize, currentPage])

    const previousPage = () => {
        setCurrentPage(page => Math.max(1, page - 1))
    }
    const nextPage = () => {
        setCurrentPage(page => Math.min(maxPageSize, page + 1))
    }

    return (
        <div className="page-list">
            <div className="page-list-header">
                {
                    onHeadRender()
                }
            </div>
            <div className="page-list-content">
                {
                    filteredData.slice(pageIndexBegin, pageIndexEnd).map((elem, index) => {
                        return onRender(elem, index)
                    })
                }
            </div>
            <div className="page-list-footer" ref={footRef}>
                <button onClick={previousPage}>上一页</button>
                <PageButtons 
                    currentPage={currentPage} 
                    maxPage={maxPageSize} 
                    onPageChange={(page) => setCurrentPage(page)}
                    leftSize={pageButtonCounts}
                    rightSize={pageButtonCounts}
                ></PageButtons>
                <button onClick={nextPage}>下一页</button>
            </div>
        </div>
    )
}

PageList.propTypes = {
    data: PropTypes.array,
    onRender: PropTypes.func,
    defaultPageSize: PropTypes.number
};

export default PageList;