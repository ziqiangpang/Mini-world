#!/bin/bash

# ============================================
# 服务故障自愈脚本（终极稳定版）
# 功能：监控Nginx服务，异常时自动重启并记录日志
# 使用方法：bash service_autoheal.sh
# 可放入crontab定时执行（推荐每5分钟检查一次）
# ============================================

# 配置区（可根据需要调整）
SERVICE_NAME="nginx"           # 监控的服务名称
CHECK_URL="http://localhost:8080"  # 用curl检查的URL
MAX_RETRY=3                    # 最大重试次数
LOG_FILE="/data/data/com.termux/files/home/autoheal.log"  # 日志文件路径

# 颜色定义（输出更友好）
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# 检查服务状态函数
check_service() {
    # 方法1：检查进程是否存在
    pgrep -x "$SERVICE_NAME" > /dev/null
    if [ $? -eq 0 ]; then
        # 方法2：检查HTTP访问是否正常
        HTTP_CODE=$(curl -o /dev/null -s -w "%{http_code}" "$CHECK_URL" 2>/dev/null)
        if [ "$HTTP_CODE" = "200" ]; then
            log "${GREEN}✅ 服务运行正常${NC}"
            return 0
        else
            log "${YELLOW}⚠️ 进程存在但HTTP访问异常 (状态码: $HTTP_CODE)${NC}"
            return 1
        fi
    else
        log "${RED}❌ 服务进程不存在${NC}"
        return 1
    fi
}

# 重启服务函数
restart_service() {
    log "${YELLOW}🔄 尝试重启服务...${NC}"
    if command -v nginx &> /dev/null; then
        # 如果是Termux环境，可能需要用不同的启动方式
        if [ -f "/data/data/com.termux/files/usr/etc/nginx/nginx.conf" ]; then
            nginx -s stop 2>/dev/null
            nginx 2>/dev/null
        else
            # 其他环境
            systemctl restart nginx 2>/dev/null || service nginx restart 2>/dev/null
        fi
        
        # 等待服务启动
        sleep 3
        
        # 检查是否重启成功
        if check_service; then
            log "${GREEN}✅ 服务重启成功${NC}"
            return 0
        else
            log "${RED}❌ 服务重启失败${NC}"
            return 1
        fi
    else
        log "${RED}❌ 未找到nginx命令${NC}"
        return 1
    fi
}

# 主监控循环
main() {
    log "${GREEN}🚀 开始监控服务: $SERVICE_NAME${NC}"
    log "检查URL: $CHECK_URL"
    log "最大重试次数: $MAX_RETRY"
    
    while true; do
        if ! check_service; then
            log "${RED}🔴 服务异常，开始自动恢复...${NC}"
            
            # 重试机制
            for ((i=1; i<=MAX_RETRY; i++)); do
                log "${YELLOW}🔄 第 $i 次重试...${NC}"
                if restart_service; then
                    break
                elif [ $i -eq $MAX_RETRY ]; then
                    log "${RED}❌ 已达到最大重试次数，服务仍不可用${NC}"
                    # 这里可以添加告警逻辑，比如发送邮件或短信
                fi
                sleep 2
            done
        fi
        
        # 每隔5秒检查一次
        sleep 5
    done
}

# 执行主函数
main

