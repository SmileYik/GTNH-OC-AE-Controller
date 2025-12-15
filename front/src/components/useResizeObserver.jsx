import { useState, useEffect } from 'react';

/**
 * 监测指定元素尺寸变化的自定义 Hook
 * @param {object} ref - React.useRef 对象，用于绑定到 DOM 元素
 * @returns {{width: number, height: number}} - 元素的当前宽度和高度
 */
const useResizeObserver = (ref) => {
    const [dimensions, setDimensions] = useState({ width: 0, height: 0 });

    useEffect(() => {
        const element = ref.current;

        if (!element || typeof ResizeObserver === 'undefined') {
            console.log("notsupport")
            return;
        }

        const initialRect = element.getBoundingClientRect();
        setDimensions({ width: initialRect.width, height: initialRect.height });

        const observer = new ResizeObserver(entries => {
            if (!entries || entries.length === 0) {
                return;
            }

            const { width, height } = entries[0].contentRect;

            setDimensions({ width, height });
        });

        observer.observe(element);

        return () => {
            observer.unobserve(element);
        };
    }, [ref]);

    return dimensions;
};

export default useResizeObserver;