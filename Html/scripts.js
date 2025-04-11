// TransSuccess 主脚本文件

// 当文档加载完成时执行
document.addEventListener('DOMContentLoaded', function() {
    console.log('TransSuccess 文档已加载');
    
    // 初始化页面功能
    initPage();
});

// 页面初始化函数
function initPage() {
    // 添加平滑滚动效果
    addSmoothScrolling();
    
    // 添加响应式导航菜单
    setupResponsiveNav();
    
    // 添加返回顶部按钮
    addBackToTopButton();
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
    backToTopButton.title = '返回顶部';
    
    // 设置按钮样式
    backToTopButton.style.position = 'fixed';
    backToTopButton.style.bottom = '20px';
    backToTopButton.style.right = '20px';
    backToTopButton.style.display = 'none';
    backToTopButton.style.padding = '10px 15px';
    backToTopButton.style.backgroundColor = '#3498db';
    backToTopButton.style.color = 'white';
    backToTopButton.style.border = 'none';
    backToTopButton.style.borderRadius = '5px';
    backToTopButton.style.cursor = 'pointer';
    backToTopButton.style.fontSize = '18px';
    backToTopButton.style.zIndex = '1000';
    
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
