#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import chardet
import csv
from datetime import datetime

def detect_file_encoding(file_path):
    """检测文件编码"""
    try:
        with open(file_path, 'rb') as f:
            raw_data = f.read()
            result = chardet.detect(raw_data)
            return result
    except Exception as e:
        return {'encoding': None, 'confidence': 0, 'error': str(e)}

def process_directory(dir_path, output_csv):
    """处理目录中的所有文件"""
    results = []
    
    for root, _, files in os.walk(dir_path):
        for file in files:
            # 只处理文本文件
            if file.endswith(('.txt', '.csv', '.ini', '.log', '.xml', '.json', '.htm', '.html', '.css', '.js', '.md')):
                file_path = os.path.join(root, file)
                result = detect_file_encoding(file_path)
                result['file'] = file_path
                results.append(result)
                print(f"文件: {file_path}")
                print(f"编码: {result['encoding']}")
                print(f"置信度: {result['confidence']}")
                print("-" * 50)
    
    # 保存结果到CSV文件
    if results:
        with open(output_csv, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow(['文件', '编码', '置信度'])
            for result in results:
                writer.writerow([
                    result['file'],
                    result['encoding'],
                    result['confidence']
                ])
        print(f"结果已保存到: {output_csv}")
    
    return results

def main():
    # 检查命令行参数
    if len(sys.argv) < 2:
        print("用法: python check_encodings.py <目录路径> [输出CSV文件]")
        return 1
    
    dir_path = sys.argv[1]
    if not os.path.exists(dir_path):
        print(f"错误: 目录不存在 - {dir_path}")
        return 1
    
    # 如果未指定输出文件，则使用默认名称
    output_csv = sys.argv[2] if len(sys.argv) > 2 else "encoding_results.csv"
    
    process_directory(dir_path, output_csv)
    return 0

if __name__ == '__main__':
    sys.exit(main())
