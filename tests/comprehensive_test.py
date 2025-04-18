#!/usr/bin/env python
# -*- coding: utf-8 -*-

import os
import sys
import csv
import chardet
import codecs
import shutil
import random
import time
from datetime import datetime
import itertools

# 定义各种编码
TARGET_ENCODINGS = [
    'utf-8',
    'utf-8-sig',
    'utf-16',
    'utf-16-le',
    'utf-16-be',
    'latin-1',
    'cp1252',
    'iso8859-2',
    'cp1250',
    'gb2312',
    'gbk',
    'big5',
    'shift_jis',
    'euc_jp',
    'euc_kr',
    'cp949',
    'cp1256',
    'cp1255',
    'cp1251',
    'koi8-r'
]

def detect_file_encoding(file_path):
    """检测文件编码"""
    try:
        with open(file_path, 'rb') as f:
            raw_data = f.read()
            result = chardet.detect(raw_data)
            return result
    except Exception as e:
        return {'encoding': None, 'confidence': 0, 'error': str(e)}

def convert_file_encoding(source_file, target_file, target_encoding='utf-8', add_bom=False):
    """转换文件编码"""
    try:
        # 检测源文件编码
        result = detect_file_encoding(source_file)
        source_encoding = result['encoding']
        
        if not source_encoding:
            return {'success': False, 'error': f"无法检测源文件编码 - {source_file}"}
        
        # 读取源文件内容
        with open(source_file, 'rb') as f:
            content = f.read()
        
        # 解码内容
        try:
            text = content.decode(source_encoding)
        except UnicodeDecodeError:
            return {'success': False, 'error': f"无法使用检测到的编码 {source_encoding} 解码文件 - {source_file}"}
        
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
        
        return {'success': True, 'source_encoding': source_encoding, 'target_encoding': target_encoding}
    except Exception as e:
        return {'success': False, 'error': str(e)}

def run_detection_test(test_files, output_csv):
    """运行编码检测测试"""
    results = []
    
    for file_path in test_files:
        start_time = time.time()
        result = detect_file_encoding(file_path)
        end_time = time.time()
        
        detection_time = (end_time - start_time) * 1000  # 转换为毫秒
        
        result['file'] = file_path
        result['detection_time_ms'] = detection_time
        results.append(result)
        
        print(f"文件: {file_path}")
        print(f"检测到的编码: {result['encoding']}")
        print(f"置信度: {result['confidence']}")
        print(f"检测时间: {detection_time:.2f} ms")
        print("-" * 50)
    
    # 保存结果到CSV文件
    if results:
        with open(output_csv, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow(['文件', '检测到的编码', '置信度', '检测时间(ms)'])
            for result in results:
                writer.writerow([
                    result['file'],
                    result['encoding'],
                    result['confidence'],
                    result['detection_time_ms']
                ])
        print(f"检测结果已保存到: {output_csv}")
    
    return results

def run_conversion_test(test_files, output_dir, target_encodings, output_csv):
    """运行编码转换测试"""
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    results = []
    total_tests = 0
    successful_tests = 0
    
    # 为每个测试文件和目标编码创建转换测试
    for file_path in test_files:
        for target_encoding in target_encodings:
            for add_bom in [False, True]:
                if target_encoding.lower() != 'utf-8' and add_bom:
                    continue  # 只有UTF-8支持BOM选项
                
                total_tests += 1
                
                # 构建目标文件路径
                file_name = os.path.basename(file_path)
                bom_suffix = "_bom" if add_bom else ""
                target_file = os.path.join(output_dir, f"{os.path.splitext(file_name)[0]}_{target_encoding.replace('-', '_')}{bom_suffix}{os.path.splitext(file_name)[1]}")
                
                # 转换文件
                start_time = time.time()
                conversion_result = convert_file_encoding(file_path, target_file, target_encoding, add_bom)
                end_time = time.time()
                
                conversion_time = (end_time - start_time) * 1000  # 转换为毫秒
                
                # 记录结果
                result = {
                    'source_file': file_path,
                    'target_file': target_file,
                    'target_encoding': target_encoding,
                    'add_bom': add_bom,
                    'success': conversion_result.get('success', False),
                    'conversion_time_ms': conversion_time
                }
                
                if conversion_result.get('success', False):
                    result['source_encoding'] = conversion_result.get('source_encoding', 'unknown')
                    successful_tests += 1
                else:
                    result['error'] = conversion_result.get('error', 'unknown error')
                
                results.append(result)
                
                # 打印结果
                status = "成功" if result['success'] else "失败"
                print(f"转换测试 {total_tests}: {file_path} -> {target_file}")
                print(f"目标编码: {target_encoding}, 添加BOM: {add_bom}")
                print(f"结果: {status}")
                if not result['success']:
                    print(f"错误: {result.get('error', 'unknown error')}")
                print(f"转换时间: {conversion_time:.2f} ms")
                print("-" * 50)
                
                # 如果已经达到指定的测试次数，则停止
                if total_tests >= 200:
                    break
            
            if total_tests >= 200:
                break
        
        if total_tests >= 200:
            break
    
    # 保存结果到CSV文件
    if results:
        with open(output_csv, 'w', newline='', encoding='utf-8') as f:
            writer = csv.writer(f)
            writer.writerow(['源文件', '目标文件', '目标编码', '添加BOM', '成功', '源编码', '转换时间(ms)', '错误'])
            for result in results:
                writer.writerow([
                    result['source_file'],
                    result['target_file'],
                    result['target_encoding'],
                    result['add_bom'],
                    result['success'],
                    result.get('source_encoding', ''),
                    result['conversion_time_ms'],
                    result.get('error', '')
                ])
        print(f"转换结果已保存到: {output_csv}")
    
    print(f"总共执行了 {total_tests} 次转换测试，成功 {successful_tests} 次，成功率: {successful_tests/total_tests*100:.2f}%")
    
    return results

def generate_html_report(detection_results, conversion_results, output_file):
    """生成HTML测试报告"""
    # 计算检测统计信息
    total_detection = len(detection_results)
    successful_detection = sum(1 for r in detection_results if r['encoding'] is not None)
    high_confidence_detection = sum(1 for r in detection_results if r.get('confidence', 0) >= 0.8)
    
    # 计算转换统计信息
    total_conversion = len(conversion_results)
    successful_conversion = sum(1 for r in conversion_results if r['success'])
    
    # 按编码分组的成功率
    encoding_success_rates = {}
    for target_encoding in set(r['target_encoding'] for r in conversion_results):
        tests = [r for r in conversion_results if r['target_encoding'] == target_encoding]
        successful = sum(1 for r in tests if r['success'])
        encoding_success_rates[target_encoding] = {
            'total': len(tests),
            'successful': successful,
            'rate': successful / len(tests) if len(tests) > 0 else 0
        }
    
    # 生成HTML报告
    html = f"""<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>编码检测和转换综合测试报告</title>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; }}
        h1, h2, h3 {{ color: #333; }}
        table {{ border-collapse: collapse; width: 100%; margin-bottom: 20px; }}
        th, td {{ border: 1px solid #ddd; padding: 8px; text-align: left; }}
        th {{ background-color: #f2f2f2; }}
        tr:nth-child(even) {{ background-color: #f9f9f9; }}
        .success {{ color: green; }}
        .failure {{ color: red; }}
        .summary {{ margin-bottom: 20px; }}
        .chart {{ width: 100%; height: 300px; margin-bottom: 20px; }}
    </style>
    <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body>
    <h1>编码检测和转换综合测试报告</h1>
    <p>生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}</p>
    
    <h2>1. 编码检测测试摘要</h2>
    <div class="summary">
        <p>总测试文件数: {total_detection}</p>
        <p>成功检测编码: {successful_detection} ({successful_detection/total_detection*100:.2f}%)</p>
        <p>高置信度检测(>=0.8): {high_confidence_detection} ({high_confidence_detection/total_detection*100:.2f}%)</p>
    </div>
    
    <div class="chart">
        <canvas id="detectionChart"></canvas>
    </div>
    
    <h2>2. 编码转换测试摘要</h2>
    <div class="summary">
        <p>总转换测试次数: {total_conversion}</p>
        <p>成功转换次数: {successful_conversion} ({successful_conversion/total_conversion*100:.2f}%)</p>
    </div>
    
    <div class="chart">
        <canvas id="conversionChart"></canvas>
    </div>
    
    <h3>各目标编码的转换成功率</h3>
    <table>
        <tr>
            <th>目标编码</th>
            <th>测试次数</th>
            <th>成功次数</th>
            <th>成功率</th>
        </tr>
"""
    
    # 添加各编码的成功率
    for encoding, stats in encoding_success_rates.items():
        html += f"""        <tr>
            <td>{encoding}</td>
            <td>{stats['total']}</td>
            <td>{stats['successful']}</td>
            <td>{stats['rate']*100:.2f}%</td>
        </tr>
"""
    
    html += """    </table>
    
    <h2>3. 编码检测详细结果</h2>
    <table>
        <tr>
            <th>文件</th>
            <th>检测到的编码</th>
            <th>置信度</th>
            <th>检测时间(ms)</th>
        </tr>
"""
    
    # 添加检测详细结果
    for result in detection_results:
        confidence = result.get('confidence', 0)
        confidence_class = 'success' if confidence >= 0.8 else 'failure'
        html += f"""        <tr>
            <td>{os.path.basename(result['file'])}</td>
            <td>{result['encoding']}</td>
            <td class="{confidence_class}">{confidence:.2f}</td>
            <td>{result.get('detection_time_ms', 0):.2f}</td>
        </tr>
"""
    
    html += """    </table>
    
    <h2>4. 编码转换详细结果</h2>
    <table>
        <tr>
            <th>源文件</th>
            <th>目标编码</th>
            <th>添加BOM</th>
            <th>结果</th>
            <th>源编码</th>
            <th>转换时间(ms)</th>
        </tr>
"""
    
    # 添加转换详细结果（限制显示前100个结果）
    for result in conversion_results[:100]:
        status_class = 'success' if result['success'] else 'failure'
        status_text = '成功' if result['success'] else '失败'
        html += f"""        <tr>
            <td>{os.path.basename(result['source_file'])}</td>
            <td>{result['target_encoding']}</td>
            <td>{result['add_bom']}</td>
            <td class="{status_class}">{status_text}</td>
            <td>{result.get('source_encoding', '')}</td>
            <td>{result['conversion_time_ms']:.2f}</td>
        </tr>
"""
    
    html += """    </table>
    
    <h2>5. 结论和建议</h2>
    <p>通过综合测试，我们发现：</p>
    <ol>
        <li>chardet库在检测多种编码方面表现良好，特别是对于UTF-8和常见的亚洲语言编码。</li>
        <li>编码转换的成功率受源文件编码检测准确性的影响。</li>
        <li>某些编码组合的转换可能会失败，特别是当源编码和目标编码的字符集不兼容时。</li>
        <li>添加BOM标记对于UTF-8文件的识别有帮助，但可能会导致某些应用程序的兼容性问题。</li>
    </ol>
    
    <p>建议：</p>
    <ol>
        <li>改进编码检测算法，特别是对于低置信度的情况。</li>
        <li>提供更多的编码选项和转换路径。</li>
        <li>添加错误处理和回退机制，以处理转换失败的情况。</li>
        <li>考虑使用机器学习方法来提高编码检测的准确性。</li>
    </ol>
    
    <script>
        // 检测结果图表
        var detectionCtx = document.getElementById('detectionChart').getContext('2d');
        var detectionChart = new Chart(detectionCtx, {
            type: 'pie',
            data: {
                labels: ['成功检测', '检测失败'],
                datasets: [{
                    data: [""" + f"{successful_detection}, {total_detection - successful_detection}" + """],
                    backgroundColor: ['#4CAF50', '#F44336']
                }]
            },
            options: {
                responsive: true,
                title: {
                    display: true,
                    text: '编码检测结果'
                }
            }
        });
        
        // 转换结果图表
        var conversionCtx = document.getElementById('conversionChart').getContext('2d');
        var conversionChart = new Chart(conversionCtx, {
            type: 'pie',
            data: {
                labels: ['成功转换', '转换失败'],
                datasets: [{
                    data: [""" + f"{successful_conversion}, {total_conversion - successful_conversion}" + """],
                    backgroundColor: ['#4CAF50', '#F44336']
                }]
            },
            options: {
                responsive: true,
                title: {
                    display: true,
                    text: '编码转换结果'
                }
            }
        });
    </script>
</body>
</html>"""
    
    # 保存HTML报告
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(html)
    
    print(f"HTML报告已生成: {output_file}")

def main():
    # 检查命令行参数
    if len(sys.argv) < 2:
        print("用法: python comprehensive_test.py <测试文件目录> [输出目录]")
        return 1
    
    test_files_dir = sys.argv[1]
    output_dir = sys.argv[2] if len(sys.argv) > 2 else "test_results"
    
    if not os.path.exists(test_files_dir):
        print(f"错误: 测试文件目录不存在 - {test_files_dir}")
        return 1
    
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    # 获取测试文件列表
    test_files = []
    for root, _, files in os.walk(test_files_dir):
        for file in files:
            if file.endswith('.txt'):
                test_files.append(os.path.join(root, file))
    
    if len(test_files) < 1:
        print(f"错误: 测试文件目录中没有.txt文件 - {test_files_dir}")
        return 1
    
    print(f"找到 {len(test_files)} 个测试文件")
    
    # 运行编码检测测试
    print("\n运行编码检测测试...")
    detection_output_csv = os.path.join(output_dir, "detection_results.csv")
    detection_results = run_detection_test(test_files, detection_output_csv)
    
    # 运行编码转换测试
    print("\n运行编码转换测试...")
    conversion_output_dir = os.path.join(output_dir, "converted_files")
    conversion_output_csv = os.path.join(output_dir, "conversion_results.csv")
    
    # 随机选择一部分目标编码，以控制测试数量
    selected_encodings = random.sample(TARGET_ENCODINGS, min(10, len(TARGET_ENCODINGS)))
    
    conversion_results = run_conversion_test(test_files, conversion_output_dir, selected_encodings, conversion_output_csv)
    
    # 生成HTML报告
    print("\n生成HTML测试报告...")
    html_report = os.path.join(output_dir, "encoding_test_report.html")
    generate_html_report(detection_results, conversion_results, html_report)
    
    print("\n测试完成!")
    print(f"检测结果: {detection_output_csv}")
    print(f"转换结果: {conversion_output_csv}")
    print(f"HTML报告: {html_report}")
    
    return 0

if __name__ == '__main__':
    sys.exit(main())
