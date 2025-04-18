#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import chardet
import argparse
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

def process_file(file_path):
    """处理单个文件"""
    result = detect_file_encoding(file_path)
    print(f"文件: {os.path.basename(file_path)}")
    print(f"编码: {result['encoding']}")
    print(f"置信度: {result['confidence']}")
    print("-" * 50)
    return result

def process_directory(dir_path, output_csv=None):
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
    
    # 如果指定了输出CSV文件，则保存结果
    if output_csv and results:
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
    parser = argparse.ArgumentParser(description='检测文件编码')
    parser.add_argument('path', help='文件或目录路径')
    parser.add_argument('--output', '-o', help='输出CSV文件路径')
    
    args = parser.parse_args()
    
    if not os.path.exists(args.path):
        print(f"错误: 路径不存在 - {args.path}")
        return 1
    
    # 如果未指定输出文件，则使用默认名称
    output_csv = args.output
    if not output_csv and os.path.isdir(args.path):
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        output_csv = f"encoding_results_{timestamp}.csv"
    
    if os.path.isdir(args.path):
        process_directory(args.path, output_csv)
    else:
        process_file(args.path)
    
    return 0

if __name__ == '__main__':
    sys.exit(main())
