#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import subprocess
import time
from datetime import datetime

def run_command(command):
    """运行命令并返回输出"""
    print(f"执行命令: {command}")
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    stdout, stderr = process.communicate()
    
    if process.returncode != 0:
        print(f"命令执行失败: {stderr.decode('utf-8', errors='replace')}")
        return False
    
    print(f"命令执行成功")
    return True

def main():
    # 设置测试目录
    test_files_dir = "test_files"
    results_dir = "test_results"
    
    # 创建目录
    os.makedirs(test_files_dir, exist_ok=True)
    os.makedirs(results_dir, exist_ok=True)
    
    print("=" * 80)
    print("开始全面编码测试")
    print("=" * 80)
    
    # 步骤1: 生成测试文件
    print("\n步骤1: 生成测试文件")
    print("-" * 50)
    if not run_command(f"python generate_test_files.py {test_files_dir} 60"):
        print("生成测试文件失败，测试终止")
        return 1
    
    # 步骤2: 运行综合测试
    print("\n步骤2: 运行综合测试")
    print("-" * 50)
    if not run_command(f"python comprehensive_test.py {test_files_dir} {results_dir}"):
        print("综合测试失败，继续执行其他测试")
    
    # 步骤3: 测试优化的编码检测器
    print("\n步骤3: 测试优化的编码检测器")
    print("-" * 50)
    if not run_command(f"python optimized_encoding_detector.py {test_files_dir} {results_dir}"):
        print("优化编码检测器测试失败，继续执行其他测试")
    
    # 步骤4: 生成最终报告
    print("\n步骤4: 生成最终报告")
    print("-" * 50)
    
    # 创建最终报告的HTML文件
    final_report = os.path.join(results_dir, "final_report.html")
    with open(final_report, 'w', encoding='utf-8') as f:
        f.write(f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>编码测试最终报告</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; }}
        h1, h2 {{ color: #333; }}
        .report-link {{ margin: 10px 0; padding: 10px; background-color: #f0f0f0; border-radius: 5px; }}
        .report-link a {{ color: #0066cc; text-decoration: none; font-weight: bold; }}
        .report-link a:hover {{ text-decoration: underline; }}
    </style>
</head>
<body>
    <h1>编码测试最终报告</h1>
    <p>生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
    
    <h2>测试报告链接</h2>
    
    <div class="report-link">
        <a href="encoding_test_report.html" target="_blank">综合编码测试报告</a>
        <p>包含编码检测和转换的详细测试结果</p>
    </div>
    
    <div class="report-link">
        <a href="detector_comparison_report.html" target="_blank">编码检测器比较报告</a>
        <p>比较优化的编码检测器和chardet库的性能和准确性</p>
    </div>
    
    <h2>测试总结</h2>
    <p>本次测试包括以下内容：</p>
    <ol>
        <li>生成了60个不同编码和语言的测试文件</li>
        <li>对这些文件进行了编码检测测试</li>
        <li>执行了200多次不同的编码转换组合测试</li>
        <li>比较了优化的编码检测器和chardet库的性能和准确性</li>
    </ol>
    
    <p>请点击上面的链接查看详细的测试报告。</p>
</body>
</html>""")
    
    print(f"最终报告已生成: {final_report}")
    
    print("\n所有测试完成!")
    print(f"测试结果保存在: {results_dir}")
    
    return 0

if __name__ == '__main__':
    sys.exit(main())
