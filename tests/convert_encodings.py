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

def convert_file_encoding(source_file, target_file, target_encoding='utf-8', add_bom=True):
    """转换文件编码"""
    try:
        # 检测源文件编码
        result = detect_file_encoding(source_file)
        source_encoding = result['encoding']
        
        if not source_encoding:
            print(f"错误: 无法检测源文件编码 - {source_file}")
            return False
        
        # 读取源文件内容
        with open(source_file, 'rb') as f:
            content = f.read()
        
        # 解码内容
        try:
            text = content.decode(source_encoding)
        except UnicodeDecodeError:
            print(f"错误: 无法使用检测到的编码 {source_encoding} 解码文件 - {source_file}")
            return False
        
        # 编码为目标编码
        if target_encoding.lower() == 'utf-8' and add_bom:
            # 添加BOM
            with open(target_file, 'wb') as f:
                f.write(b'\xef\xbb\xbf')
                f.write(text.encode(target_encoding))
        else:
            # 不添加BOM
            with open(target_file, 'wb') as f:
                f.write(text.encode(target_encoding))
        
        print(f"转换成功: {source_file} -> {target_file} ({source_encoding} -> {target_encoding})")
        return True
    except Exception as e:
        print(f"转换出错: {e}")
        return False

def process_directory(source_dir, target_dir, target_encoding='utf-8', add_bom=True):
    """处理目录中的所有文件"""
    results = []
    
    # 确保目标目录存在
    if not os.path.exists(target_dir):
        os.makedirs(target_dir)
    
    # 遍历源目录中的所有文件
    for root, _, files in os.walk(source_dir):
        for file in files:
            # 只处理文本文件
            if file.endswith(('.txt', '.csv', '.ini', '.log', '.xml', '.json', '.htm', '.html', '.css', '.js', '.md')):
                # 构建源文件和目标文件路径
                source_file = os.path.join(root, file)
                
                # 计算相对路径
                rel_path = os.path.relpath(source_file, source_dir)
                target_file = os.path.join(target_dir, rel_path)
                
                # 确保目标文件所在目录存在
                target_file_dir = os.path.dirname(target_file)
                if not os.path.exists(target_file_dir):
                    os.makedirs(target_file_dir)
                
                # 转换文件编码
                success = convert_file_encoding(source_file, target_file, target_encoding, add_bom)
                
                # 记录结果
                result = {
                    'source_file': source_file,
                    'target_file': target_file,
                    'success': success
                }
                results.append(result)
    
    return results

def main():
    # 检查命令行参数
    if len(sys.argv) < 3:
        print("用法: python convert_encodings.py <源目录> <目标目录> [目标编码] [添加BOM(true/false)]")
        return 1
    
    source_dir = sys.argv[1]
    target_dir = sys.argv[2]
    
    if not os.path.exists(source_dir):
        print(f"错误: 源目录不存在 - {source_dir}")
        return 1
    
    # 目标编码，默认为UTF-8
    target_encoding = sys.argv[3] if len(sys.argv) > 3 else 'utf-8'
    
    # 是否添加BOM，默认为True
    add_bom = True
    if len(sys.argv) > 4:
        add_bom = sys.argv[4].lower() == 'true'
    
    print(f"开始转换文件编码...")
    print(f"源目录: {source_dir}")
    print(f"目标目录: {target_dir}")
    print(f"目标编码: {target_encoding}")
    print(f"添加BOM: {add_bom}")
    print("-" * 50)
    
    results = process_directory(source_dir, target_dir, target_encoding, add_bom)
    
    # 统计结果
    success_count = sum(1 for r in results if r['success'])
    total_count = len(results)
    
    print("-" * 50)
    print(f"转换完成! 成功: {success_count}/{total_count}")
    
    return 0

if __name__ == '__main__':
    sys.exit(main())
