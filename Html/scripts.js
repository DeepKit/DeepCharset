// TransSuccess 网站脚本 - 多语言支持

// 语言数据
const translations = {
    zh: {
        // 通用
        title: "码到成功 TransSuccess - 专业文件编码转换工具",
        subtitle: "码到成功 - 让编码转换变得简单高效",
        brand_name: "码到成功",
        product_name: "TransSuccess",

        // 导航
        nav_home: "首页",
        nav_features: "功能介绍",
        nav_help: "使用帮助",
        nav_about: "关于我们",

        // 首页
        hero_title: "码到成功 - 专业编码转换，一步到位",
        hero_description: "码到成功(TransSuccess)是一款革命性的专业文件编码转换工具，让复杂的编码问题变得简单易解。采用全新改进的多层级编码检测和高级转换引擎，实现99%以上的检测准确率和100%的转换成功率。支持近100种编码格式之间的无损转换，包括UTF-8、UTF-16、UTF-32、GBK、GB18030、BIG5、GB2312、Shift-JIS等，彻底解决UTF-8与UTF-8+BOM互相转换的难题。码到成功，让您的编码转换真正做到一次成功！",
        learn_more: "了解更多",

        // 功能特性
        feature_batch_title: "批量转换",
        feature_batch_desc: "支持批量选择文件进行转换，提高工作效率。可以按文件类型筛选，轻松处理大量文件。",

        feature_detection_title: "高精度检测",
        feature_detection_desc: "采用多层级编码检测算法，通过字节模式分析和统计特征识别，准确率达99%以上。彻底解决UTF-8被误判为ANSI的问题，支持混合内容智能检测和BOM完整性验证。",

        feature_engine_title: "高级转换引擎",
        feature_engine_desc: "基于TEncodingConverter_Improved引擎，采用流式处理和缓冲区优化技术，实现100%转换成功率。支持精确BOM控制、多种错误处理策略和参数化配置，确保字节级精确转换。",

        feature_error_title: "精确错误处理",
        feature_error_desc: "实现TEncodingConversionErrorHandlingStrategy错误处理策略，支持抛出、替换、跳过和报告四种模式。提供字节级错误定位和详细错误信息，包含错误类型、位置和原因分析，确保数据完整性。",

        feature_architecture_title: "优化技术架构",
        feature_architecture_desc: "采用静态类设计模式和面向对象编程，通过CompareText字符串比较和MilliSecondsBetween精确计时，优化内存使用和性能表现。支持大文件处理，保持稳定的转换速度和内存占用。",

        feature_i18n_title: "多语言国际化",
        feature_i18n_desc: "支持16种语言的完整国际化，所有70+编码在所有语言中都有专业翻译。通过多层级验证系统，支持对400+种编码组合的全面验证，确保在各种语言环境下的稳定表现。",

        // 页脚
        copyright: "© 2024 TransSuccess. 保留所有权利。",
        back_to_top: "返回顶部",

        // 页面标题
        features_page_title: "功能介绍",
        features_page_desc: "TransSuccess 提供丰富的功能，满足您的各种文件编码转换需求。",
        help_page_title: "使用帮助",
        help_page_desc: "详细的使用指南，帮助您充分利用 TransSuccess 的所有功能。",
        about_page_title: "关于我们",
        about_page_desc: "了解 TransSuccess 的开发团队、历史和使命。"
    },

    en: {
        // 通用
        title: "CodeToSuccess TransSuccess - Professional File Encoding Converter",
        subtitle: "CodeToSuccess - Making Encoding Conversion Simple and Efficient",
        brand_name: "CodeToSuccess",
        product_name: "TransSuccess",

        // 导航
        nav_home: "Home",
        nav_features: "Features",
        nav_help: "Help",
        nav_about: "About",

        // 首页
        hero_title: "CodeToSuccess - Professional Encoding Conversion, One Step Success",
        hero_description: "CodeToSuccess (TransSuccess) is a revolutionary professional file encoding conversion tool that makes complex encoding problems simple and easy to solve. Features advanced multi-level encoding detection and high-performance conversion engine, achieving 99%+ detection accuracy and 100% conversion success rate. Supports lossless conversion between nearly 100 encoding formats including UTF-8, UTF-16, UTF-32, GBK, GB18030, BIG5, GB2312, Shift-JIS, completely solving UTF-8 to UTF-8+BOM conversion challenges. CodeToSuccess - making your encoding conversion truly successful in one go!",
        learn_more: "Learn More",

        // 功能特性
        feature_batch_title: "Batch Conversion",
        feature_batch_desc: "Support batch file selection for conversion to improve work efficiency. Filter by file type to easily handle large numbers of files.",

        feature_detection_title: "High-Precision Detection",
        feature_detection_desc: "Advanced multi-level encoding detection algorithm with byte pattern analysis and statistical feature recognition, achieving 99%+ accuracy. Completely solves UTF-8 misidentification as ANSI, supports mixed content intelligent detection and BOM integrity verification.",

        feature_engine_title: "Advanced Conversion Engine",
        feature_engine_desc: "Based on TEncodingConverter_Improved engine with streaming processing and buffer optimization technology, achieving 100% conversion success rate. Supports precise BOM control, multiple error handling strategies and parameterized configuration for byte-level accurate conversion.",

        feature_error_title: "Precise Error Handling",
        feature_error_desc: "Implements TEncodingConversionErrorHandlingStrategy with four modes: throw, replace, skip, and report. Provides byte-level error positioning and detailed error information including error type, position and cause analysis to ensure data integrity.",

        feature_architecture_title: "Optimized Technical Architecture",
        feature_architecture_desc: "Uses static class design patterns and object-oriented programming with CompareText string comparison and MilliSecondsBetween precise timing to optimize memory usage and performance. Supports large file processing while maintaining stable conversion speed and memory footprint.",

        feature_i18n_title: "Multilingual Internationalization",
        feature_i18n_desc: "Supports complete internationalization in 16 languages with professional translations for all 70+ encodings in all languages. Through multi-level validation system, supports comprehensive validation of 400+ encoding combinations, ensuring stable performance in various language environments.",

        // 页脚
        copyright: "© 2024 TransSuccess. All rights reserved.",
        back_to_top: "Back to Top",

        // 页面标题
        features_page_title: "Features",
        features_page_desc: "TransSuccess provides rich features to meet all your file encoding conversion needs.",
        help_page_title: "Help",
        help_page_desc: "Detailed user guide to help you make full use of all TransSuccess features.",
        about_page_title: "About Us",
        about_page_desc: "Learn about TransSuccess development team, history and mission."
    }
};

// 当前语言
let currentLanguage = 'zh';

// 当文档加载完成时执行
document.addEventListener('DOMContentLoaded', function() {
    console.log('TransSuccess 文档已加载');

    // 初始化多语言支持
    initLanguageSupport();

    // 初始化页面功能
    initPage();
});

// 初始化多语言支持
function initLanguageSupport() {
    // 从localStorage获取保存的语言设置
    const savedLanguage = localStorage.getItem('transsuccess-language');
    if (savedLanguage && translations[savedLanguage]) {
        currentLanguage = savedLanguage;
    }

    // 设置语言选择器
    const languageSelector = document.getElementById('languageSelector');
    if (languageSelector) {
        languageSelector.value = currentLanguage;
        languageSelector.addEventListener('change', changeLanguage);
    }

    // 应用当前语言
    applyLanguage(currentLanguage);
}

// 页面初始化函数
function initPage() {
    // 添加平滑滚动效果
    addSmoothScrolling();

    // 添加响应式导航菜单
    setupResponsiveNav();

    // 添加返回顶部按钮
    addBackToTopButton();

    // 设置当前页面的导航高亮
    highlightCurrentPage();
}

// 切换语言
function changeLanguage(event) {
    const newLanguage = event.target.value;
    currentLanguage = newLanguage;

    // 保存到localStorage
    localStorage.setItem('transsuccess-language', newLanguage);

    // 应用新语言
    applyLanguage(newLanguage);

    // 更新页面语言属性
    document.documentElement.lang = newLanguage === 'zh' ? 'zh-CN' : 'en';
}

// 应用语言
function applyLanguage(language) {
    const t = translations[language];
    if (!t) return;

    // 更新页面标题
    document.title = t.title;

    // 更新所有带有data-i18n属性的元素
    document.querySelectorAll('[data-i18n]').forEach(element => {
        const key = element.getAttribute('data-i18n');
        if (t[key]) {
            element.textContent = t[key];
        }
    });

    // 更新所有带有data-i18n-html属性的元素（支持HTML内容）
    document.querySelectorAll('[data-i18n-html]').forEach(element => {
        const key = element.getAttribute('data-i18n-html');
        if (t[key]) {
            element.innerHTML = t[key];
        }
    });

    // 更新所有带有data-i18n-placeholder属性的元素
    document.querySelectorAll('[data-i18n-placeholder]').forEach(element => {
        const key = element.getAttribute('data-i18n-placeholder');
        if (t[key]) {
            element.placeholder = t[key];
        }
    });

    // 更新所有带有data-i18n-title属性的元素
    document.querySelectorAll('[data-i18n-title]').forEach(element => {
        const key = element.getAttribute('data-i18n-title');
        if (t[key]) {
            element.title = t[key];
        }
    });
}

// 高亮当前页面导航
function highlightCurrentPage() {
    const currentPage = window.location.pathname.split('/').pop() || 'index.html';
    const navLinks = document.querySelectorAll('nav a');

    navLinks.forEach(link => {
        const href = link.getAttribute('href');
        if (href === currentPage || (currentPage === '' && href === 'index.html')) {
            link.classList.add('active');
        } else {
            link.classList.remove('active');
        }
    });
}

// 添加平滑滚动效果
function addSmoothScrolling() {
    // 获取所有内部链接
    const internalLinks = document.querySelectorAll('a[href^="#"]');

    // 为每个内部链接添加点击事件
    internalLinks.forEach(link => {
        link.addEventListener('click', function(e) {
            e.preventDefault();

            // 获取目标元素
            const targetId = this.getAttribute('href');
            const targetElement = document.querySelector(targetId);

            if (targetElement) {
                // 平滑滚动到目标元素
                targetElement.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
}

// 设置响应式导航菜单
function setupResponsiveNav() {
    // 在小屏幕上添加汉堡菜单功能
    const nav = document.querySelector('nav');
    const container = nav.querySelector('.container');

    // 创建汉堡菜单按钮
    const menuButton = document.createElement('button');
    menuButton.classList.add('menu-toggle');
    menuButton.innerHTML = '&#9776;'; // 汉堡图标
    menuButton.style.display = 'none'; // 默认隐藏

    // 将按钮添加到导航栏
    container.insertBefore(menuButton, container.firstChild);

    // 添加点击事件
    menuButton.addEventListener('click', function() {
        const navList = nav.querySelector('ul');
        navList.classList.toggle('show');
    });

    // 响应窗口大小变化
    function handleResize() {
        if (window.innerWidth <= 768) {
            menuButton.style.display = 'block';
            nav.classList.add('responsive');
        } else {
            menuButton.style.display = 'none';
            nav.classList.remove('responsive');
            nav.querySelector('ul').classList.remove('show');
        }
    }

    // 初始检查
    handleResize();

    // 监听窗口大小变化
    window.addEventListener('resize', handleResize);
}

// 添加返回顶部按钮
function addBackToTopButton() {
    // 创建返回顶部按钮
    const backToTopButton = document.createElement('button');
    backToTopButton.classList.add('back-to-top');
    backToTopButton.innerHTML = '&uarr;'; // 向上箭头
    backToTopButton.setAttribute('data-i18n-title', 'back_to_top');

    // 设置按钮样式
    backToTopButton.style.position = 'fixed';
    backToTopButton.style.bottom = '20px';
    backToTopButton.style.right = '20px';
    backToTopButton.style.display = 'none';
    backToTopButton.style.padding = '12px 15px';
    backToTopButton.style.backgroundColor = '#3498db';
    backToTopButton.style.color = 'white';
    backToTopButton.style.border = 'none';
    backToTopButton.style.borderRadius = '6px';
    backToTopButton.style.cursor = 'pointer';
    backToTopButton.style.fontSize = '18px';
    backToTopButton.style.zIndex = '1000';
    backToTopButton.style.transition = 'all 0.3s ease';
    backToTopButton.style.boxShadow = '0 2px 10px rgba(0,0,0,0.2)';

    // 添加悬停效果
    backToTopButton.addEventListener('mouseenter', function() {
        this.style.backgroundColor = '#2980b9';
        this.style.transform = 'translateY(-2px)';
    });

    backToTopButton.addEventListener('mouseleave', function() {
        this.style.backgroundColor = '#3498db';
        this.style.transform = 'translateY(0)';
    });

    // 添加到文档
    document.body.appendChild(backToTopButton);

    // 添加点击事件
    backToTopButton.addEventListener('click', function() {
        window.scrollTo({
            top: 0,
            behavior: 'smooth'
        });
    });

    // 监听滚动事件，控制按钮显示/隐藏
    window.addEventListener('scroll', function() {
        if (window.pageYOffset > 300) {
            backToTopButton.style.display = 'block';
        } else {
            backToTopButton.style.display = 'none';
        }
    });
}

// 示例：添加代码高亮功能（未实现）
function addCodeHighlighting() {
    // 这里可以添加代码高亮库的初始化代码
    console.log('代码高亮功能尚未实现');
}

// 示例：添加图像预览功能（未实现）
function addImagePreview() {
    // 这里可以添加图像预览功能的代码
    console.log('图像预览功能尚未实现');
}
