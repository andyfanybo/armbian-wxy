#!/bin/bash

# 配置参数
THRESHOLD_TEMP=40    # 开启风扇温度阈值(°C)
CHECK_INTERVAL=30    # 检查间隔(秒)
FAN_CONTROL="/sys/class/leds/FAN_GPIO/brightness"  # 风扇控制文件路径

# 获取CPU温度（兼容不同系统）
get_cpu_temp() {
    # 优先从/sys/class/thermal读取
    for temp_file in /sys/class/thermal/thermal_zone*/temp; do
        if [ -f "$temp_file" ]; then
            echo $(($(cat "$temp_file")/1000))
            return 0
        fi
    done

    # 备选方案：使用sensors命令
    if command -v sensors >/dev/null; then
        sensors | grep -E 'Package|Core' | awk '{print $3}' | grep -oE '[0-9]+' | head -1
    else
        echo "错误：无法读取CPU温度！" >&2
        exit 1
    fi
}

# 控制风扇状态
set_fan() {
    echo $1 | sudo tee "$FAN_CONTROL" >/dev/null
}

# 主循环
echo "启动风扇控制服务（>${THRESHOLD_TEMP}°C时开启）"
while true; do
    temp=$(get_cpu_temp)
    
    if [ "$temp" -gt "$THRESHOLD_TEMP" ]; then
        set_fan 1
        echo "$(date '+%Y-%m-%d %H:%M:%S') CPU温度: ${temp}°C > ${THRESHOLD_TEMP}°C → 风扇开启"
    else
        set_fan 0
        echo "$(date '+%Y-%m-%d %H:%M:%S') CPU温度: ${temp}°C ≤ ${THRESHOLD_TEMP}°C → 风扇关闭"
    fi

    sleep "$CHECK_INTERVAL"
done