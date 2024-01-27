#!/bin/bash

# 设置变量，您可以根据需要更改这些值
USERID_1=""
TOKEN_1=""
USERID_2=""
TOKEN_2=""
PUSHPLUS_TOKEN=""
NOTIFICATIONS=()

# 推送通知函数
function pushplus_notification() {
    local title="$1"
    local content="$2"
    curl -s -X POST "http://www.pushplus.plus/send" -d "token=$PUSHPLUS_TOKEN&title=$title&content=$content&template=markdown"
    
}

# 定义函数执行用户操作
function execute_user_operations() {
    local userid="$1"
    local token="$2"
    local user_note="$3" # Add a parameter for user note
    
    echo "********运行账号$user_note ($userid)********"
    
    # 获取当前时间戳
    local timestamp=$(date +%s)
    echo "选择qd_info的时间戳：$timestamp"
    
    local response=$(curl -X POST 'https://m.freecheck.cn/api/user/qd_info' \
        -H 'User-Agent: Mozilla/5.0 (Linux; Android 13; 23013RK75C Build/TKQ1.220905.001; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/116.0.0.0 Mobile Safari/537.36 XWEB/1160043 MMWEBSDK/20230805 MMWEBID/38 MicroMessenger/8.0.42.2424(0x28002A43) WeChat/arm64 Weixin GPVersion/1 NetType/WIFI Language/zh_CN ABI/arm64' \
        -H 'Content-Type: application/json' \
        -H "userid: $userid" \
        -H "token: $token" \
        -d "$timestamp" \
        -s) 
    
    #echo "qd_info的JSON 响应内容：$response"
    
    local record_id=$(echo "$response" |/data/user/0/com.termux/files/usr/bin/jq -r '.data.record_id')
    echo "提取 record_id 的值：$record_id"
    
    local sortIndex=$(echo "$response" |/data/user/0/com.termux/files/usr/bin/jq -r '.data.list[] | select(.state == 0) | .sortIndex')
    
    echo "提取 sortIndex 的值：$sortIndex"
    
    local first_sortIndex=$(echo "$sortIndex" | head -n 1)
    
    echo "选择第一个sortIndex：$first_sortIndex"
    
    local updated_timestamp=$(date +%s)
    echo "set_qd的时间戳：$updated_timestamp"
    
    local json_payload="{\"qd_id\":$record_id,\"sort_index\":$first_sortIndex,\"Timestamp\":$updated_timestamp}"
    echo "组成JSON_PAYLOAD：$json_payload"
    
    # 发送 POST 请求
    local api_response=$(curl -X POST 'https://m.freecheck.cn/api/user/set_qd' \
        -H 'User-Agent: Mozilla/5.0 (Linux; Android 13; 23013RK75C Build/TKQ1.220905.001; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/116.0.0.0 Mobile Safari/537.36 XWEB/1160043 MMWEBSDK/20230805 MMWEBID/2038 MicroMessenger/8.0.42.2424(0x28002A43) WeChat/arm64 Weixin GPVersion/1 NetType/WIFI Language/zh_CN ABI/arm64' \
        -H 'Content-Type: application/json' \
        -H "userid: $USERID_1" \
        -H "token: $TOKEN_1" \
        -d "$json_payload" \
        -s) # 使用 -s 参数静默模式输出

    # 打印当前账号的 API 响应
    #echo "账号$userid 的 API 响应：$api_response"
    
    # 将通知添加到数组
    NOTIFICATIONS+=("$user_note ($userid)，$api_response
    ")
    
    echo "********结束账号$user_note ($userid)操作********"

    # 随机等待5到6秒
    SECONDS_TO_WAIT=$((RANDOM % 30 + 10))
    sleep $SECONDS_TO_WAIT
}

# 执行所有用户操作
execute_user_operations "$USERID_1" "$TOKEN_1" "些许期待"
execute_user_operations "$USERID_2" "$TOKEN_2" "小号175"

# 构造通知内容
NOTIFICATION_CONTENT=$(IFS=$'\n'; echo "${NOTIFICATIONS[*]}")

# 推送通知
pushplus_notification "签到通知" "$NOTIFICATION_CONTENT"
