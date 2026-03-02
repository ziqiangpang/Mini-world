#!/usr/bin/env python3
"""
运维日志监控与告警脚本
功能：
1. 实时监控系统日志文件
2. 检测预设的关键错误词
3. 统计错误频率并告警
4. 生成简易监控报告
使用方法：python3 log_monitor.py
"""

import time
import re
from datetime import datetime
import os

# ========== 配置区（根据你的环境修改）==========
LOG_FILE = "/data/data/com.termux/files/usr/var/log/syslog"  # 这里用系统日志测试，避免找不到文件

# 要监控的错误关键词（可根据实际需求增减）
ERROR_KEYWORDS = ["error", "Error", "ERROR", "failed", "Failed", "timeout", "Timeout"]

# 告警阈值（单位时间内出现多少次错误就告警）
ALERT_THRESHOLD = 5  # 每10秒内出现5次错误就告警
CHECK_INTERVAL = 10  # 检查间隔（秒）

# 报告文件
REPORT_FILE = "/data/data/com.termux/files/home/log_report.txt"

def monitor_log():
    """监控日志并告警"""
    print(f"[{datetime.now()}] 开始监控日志文件: {LOG_FILE}")
    error_count = 0
    last_position = 0

    try:
        while True:
            if not os.path.exists(LOG_FILE):
                print(f"日志文件不存在: {LOG_FILE}")
                time.sleep(CHECK_INTERVAL)
                continue

            with open(LOG_FILE, 'r', encoding='utf-8') as f:
                f.seek(last_position)
                new_lines = f.readlines()
                last_position = f.tell()

            for line in new_lines:
                # 检查是否包含错误关键词
                if any(keyword in line for keyword in ERROR_KEYWORDS):
                    error_count += 1
                    print(f"[{datetime.now()}] 发现错误: {line.strip()}")

                    # 达到告警阈值时触发告警
                    if error_count >= ALERT_THRESHOLD:
                        alert_msg = f"[{datetime.now()}] 告警：在{CHECK_INTERVAL}秒内发现{error_count}次错误，请检查系统！"
                        print(alert_msg)
                        # 写入报告文件
                        with open(REPORT_FILE, 'a', encoding='utf-8') as report:
                            report.write(alert_msg + '\n')
                        error_count = 0  # 重置计数

            time.sleep(CHECK_INTERVAL)

    except KeyboardInterrupt:
        print("\n监控已停止。")

if __name__ == "__main__":
    monitor_log()
