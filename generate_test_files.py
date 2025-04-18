#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import codecs
import argparse

# 测试文本
TEST_TEXTS = {
    'chinese': '这是一个中文测试文本。包含汉字、标点符号和数字123。',
    'english': 'This is an English test text. It contains letters, punctuation, and numbers 123.',
    'mixed': 'This is a mixed text. 这是一个混合文本。English and 中文 together. 数字123和ABC。',
    'special': '特殊字符测试：！@#￥%……&*（）——+【】、；'："，。、《》？\n换行符测试\t制表符测试',
}

# 编码列表
ENCODINGS = [
    'utf-8',
    'utf-8-sig',  # UTF-8 with BOM
    'utf-16',
    'utf-16-le',
    'utf-16-be',
    'gb2312',
    'gbk',
    'gb18030',
    'big5',
    'shift_jis',
    'euc-jp',
    'euc-kr',
    'iso-8859-1',
    'windows-1252',
]

def create_test_file(output_dir, text_type, encoding, with_bom=False):
    """创建测试文件"""
    text = TEST_TEXTS.get(text_type, TEST_TEXTS['mixed'])
    
    # 构建文件名
    bom_str = '_bom' if with_bom and encoding.startswith('utf') else ''
    filename = f"{text_type}_{encoding.replace('-', '_')}{bom_str}.txt"
    filepath = os.path.join(output_dir, filename)
    
    # 写入文件
    try:
        # 对于UTF编码，可以控制是否添加BOM
        if encoding.startswith('utf'):
            if with_bom:
                # 使用带BOM的编码
                if encoding == 'utf-8':
                    encoding = 'utf-8-sig'
                # 其他UTF编码默认带BOM
            else:
                # 确保UTF-8不带BOM
                if encoding == 'utf-8-sig':
                    encoding = 'utf-8'
        
        with codecs.open(filepath, 'w', encoding=encoding) as f:
            f.write(text)
        
        print(f"已创建文件: {filename} (编码: {encoding})")
        return filepath
    except Exception as e:
        print(f"创建文件失败: {filename} - {str(e)}")
        return None

def main():
    parser = argparse.ArgumentParser(description='生成各种编码的测试文件')
    parser.add_argument('--output', '-o', default='TestFiles', help='输出目录')
    parser.add_argument('--text-type', '-t', choices=TEST_TEXTS.keys(), default='mixed', help='文本类型')
    
    args = parser.parse_args()
    
    # 创建输出目录
    if not os.path.exists(args.output):
        os.makedirs(args.output)
    
    # 生成所有编码的测试文件
    created_files = []
    for encoding in ENCODINGS:
        # 对于UTF编码，生成带BOM和不带BOM两种版本
        if encoding.startswith('utf'):
            file1 = create_test_file(args.output, args.text_type, encoding, False)
            file2 = create_test_file(args.output, args.text_type, encoding, True)
            if file1:
                created_files.append(file1)
            if file2:
                created_files.append(file2)
        else:
            file = create_test_file(args.output, args.text_type, encoding)
            if file:
                created_files.append(file)
    
    print(f"\n共创建了 {len(created_files)} 个测试文件在 {args.output} 目录中")
    
    return 0

if __name__ == '__main__':
    sys.exit(main())
