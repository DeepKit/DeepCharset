#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import csv
import filecmp
import difflib
from datetime import datetime

def load_csv_results(delphi_csv, python_csv):
    """加载CSV结果文件"""
    delphi_results = {}
    python_results = {}
    
    # 加载Delphi结果
    with open(delphi_csv, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        next(reader)  # 跳过标题行
        for row in reader:
            if len(row) >= 2:
                file_path = row[0].strip('"')
                encoding = row[1].strip('"')
                delphi_results[file_path] = encoding
    
    # 加载Python结果
    with open(python_csv, 'r', encoding='utf-8') as f:
        reader = csv.reader(f)
        next(reader)  # 跳过标题行
        for row in reader:
            if len(row) >= 2:
                file_path = row[0]
                encoding = row[1]
                python_results[file_path] = encoding
    
    return delphi_results, python_results

def compare_detection_results(delphi_results, python_results):
    """比较编码检测结果"""
    all_files = set(delphi_results.keys()) | set(python_results.keys())
    match_count = 0
    mismatch_count = 0
    missing_count = 0
    
    results = []
    
    for file_path in sorted(all_files):
        delphi_encoding = delphi_results.get(file_path, 'N/A')
        python_encoding = python_results.get(file_path, 'N/A')
        
        if delphi_encoding == 'N/A' or python_encoding == 'N/A':
            status = '缺失'
            missing_count += 1
        elif delphi_encoding.lower() == python_encoding.lower():
            status = '匹配'
            match_count += 1
        else:
            status = '不匹配'
            mismatch_count += 1
        
        results.append({
            'file': file_path,
            'delphi': delphi_encoding,
            'python': python_encoding,
            'status': status
        })
    
    return results, match_count, mismatch_count, missing_count

def compare_converted_files(delphi_dir, python_dir):
    """比较转换后的文件"""
    delphi_files = []
    python_files = []
    
    # 获取Delphi转换的文件
    for root, _, files in os.walk(delphi_dir):
        for file in files:
            file_path = os.path.join(root, file)
            rel_path = os.path.relpath(file_path, delphi_dir)
            delphi_files.append(rel_path)
    
    # 获取Python转换的文件
    for root, _, files in os.walk(python_dir):
        for file in files:
            file_path = os.path.join(root, file)
            rel_path = os.path.relpath(file_path, python_dir)
            python_files.append(rel_path)
    
    # 比较文件列表
    all_files = set(delphi_files) | set(python_files)
    match_count = 0
    mismatch_count = 0
    missing_count = 0
    
    results = []
    
    for rel_path in sorted(all_files):
        delphi_file = os.path.join(delphi_dir, rel_path)
        python_file = os.path.join(python_dir, rel_path)
        
        if not os.path.exists(delphi_file) or not os.path.exists(python_file):
            status = '缺失'
            missing_count += 1
        elif filecmp.cmp(delphi_file, python_file, shallow=False):
            status = '匹配'
            match_count += 1
        else:
            status = '不匹配'
            mismatch_count += 1
        
        results.append({
            'file': rel_path,
            'delphi_exists': os.path.exists(delphi_file),
            'python_exists': os.path.exists(python_file),
            'status': status
        })
    
    return results, match_count, mismatch_count, missing_count

def save_comparison_results(detection_results, conversion_results, output_file):
    """保存比较结果到HTML文件"""
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write('''<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>编码检测和转换比较结果</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #333; }
        table { border-collapse: collapse; width: 100%; margin-bottom: 20px; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #f2f2f2; }
        tr:nth-child(even) { background-color: #f9f9f9; }
        .match { color: green; }
        .mismatch { color: red; }
        .missing { color: orange; }
        .summary { margin-bottom: 20px; }
    </style>
</head>
<body>
    <h1>编码检测和转换比较结果</h1>
    <p>生成时间: ''' + datetime.now().strftime('%Y-%m-%d %H:%M:%S') + '''</p>
    
    <h2>1. 编码检测结果比较</h2>
    <div class="summary">
        <p>匹配: ''' + str(detection_results[1]) + '''</p>
        <p>不匹配: ''' + str(detection_results[2]) + '''</p>
        <p>缺失: ''' + str(detection_results[3]) + '''</p>
    </div>
    
    <table>
        <tr>
            <th>文件</th>
            <th>Delphi检测结果</th>
            <th>Python检测结果</th>
            <th>状态</th>
        </tr>
''')
        
        for result in detection_results[0]:
            status_class = 'match' if result['status'] == '匹配' else ('mismatch' if result['status'] == '不匹配' else 'missing')
            f.write(f'''        <tr>
            <td>{result['file']}</td>
            <td>{result['delphi']}</td>
            <td>{result['python']}</td>
            <td class="{status_class}">{result['status']}</td>
        </tr>
''')
        
        f.write('''    </table>
    
    <h2>2. 编码转换结果比较</h2>
    <div class="summary">
        <p>匹配: ''' + str(conversion_results[1]) + '''</p>
        <p>不匹配: ''' + str(conversion_results[2]) + '''</p>
        <p>缺失: ''' + str(conversion_results[3]) + '''</p>
    </div>
    
    <table>
        <tr>
            <th>文件</th>
            <th>Delphi转换</th>
            <th>Python转换</th>
            <th>状态</th>
        </tr>
''')
        
        for result in conversion_results[0]:
            status_class = 'match' if result['status'] == '匹配' else ('mismatch' if result['status'] == '不匹配' else 'missing')
            f.write(f'''        <tr>
            <td>{result['file']}</td>
            <td>{'存在' if result['delphi_exists'] else '不存在'}</td>
            <td>{'存在' if result['python_exists'] else '不存在'}</td>
            <td class="{status_class}">{result['status']}</td>
        </tr>
''')
        
        f.write('''    </table>
</body>
</html>''')

def main():
    # 检查命令行参数
    if len(sys.argv) < 5:
        print("用法: python compare_results.py <Delphi检测结果CSV> <Python检测结果CSV> <Delphi转换目录> <Python转换目录> [输出HTML文件]")
        return 1
    
    delphi_csv = sys.argv[1]
    python_csv = sys.argv[2]
    delphi_dir = sys.argv[3]
    python_dir = sys.argv[4]
    
    if not os.path.exists(delphi_csv):
        print(f"错误: Delphi检测结果文件不存在 - {delphi_csv}")
        return 1
    
    if not os.path.exists(python_csv):
        print(f"错误: Python检测结果文件不存在 - {python_csv}")
        return 1
    
    if not os.path.exists(delphi_dir):
        print(f"错误: Delphi转换目录不存在 - {delphi_dir}")
        return 1
    
    if not os.path.exists(python_dir):
        print(f"错误: Python转换目录不存在 - {python_dir}")
        return 1
    
    # 如果未指定输出文件，则使用默认名称
    output_file = sys.argv[5] if len(sys.argv) > 5 else "comparison_results.html"
    
    print("开始比较结果...")
    
    # 加载检测结果
    print("加载编码检测结果...")
    delphi_results, python_results = load_csv_results(delphi_csv, python_csv)
    
    # 比较检测结果
    print("比较编码检测结果...")
    detection_results = compare_detection_results(delphi_results, python_results)
    
    # 比较转换结果
    print("比较编码转换结果...")
    conversion_results = compare_converted_files(delphi_dir, python_dir)
    
    # 保存比较结果
    print(f"保存比较结果到 {output_file}...")
    save_comparison_results(detection_results, conversion_results, output_file)
    
    print("比较完成!")
    print(f"结果已保存到: {output_file}")
    
    return 0

if __name__ == '__main__':
    sys.exit(main())
