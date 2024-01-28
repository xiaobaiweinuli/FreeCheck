#!/bin/bash
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
# 设置变量，您可以根据需要更改这些值
USERID_1="$USERID_1"
TOKEN_1="$TOKEN_1"
USERID_2="$USERID_2"
TOKEN_2="$TOKEN_2"
PUSHPLUS_TOKEN="$PUSHPLUS_TOKEN"
NOTIFICATIONS=()
USER_COUNT=0  # Counter to keep track of the number of users processed
TOTAL_USERS=2  # Set the total number of users

# 推送通知函数
function pushplus_notification() {
    local title="$1"
    local content="$2"
    curl -s -X POST "http://www.pushplus.plus/send" -d "token=$PUSHPLUS_TOKEN&title=$title&content=$content&template=markdown"
}

# 随机等待函数
function random_wait() {
    local min_seconds=$1
    local max_seconds=$2
    local seconds_to_wait=$((RANDOM % (max_seconds - min_seconds + 1) + min_seconds))
    sleep $seconds_to_wait
}

# 定义函数执行用户操作
function execute_user_operations() {
    local userid="$1"
    local token="$2"
    local user_note="$3" # Add a parameter for user note
    
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
    
    local record_id=$(echo "$response" | jq -r '.data.record_id')
    
    local sortIndex=$(echo "$response" | jq -r '.data.list[] | select(.state == 0) | .sortIndex')
    
    local first_sortIndex=$(echo "$sortIndex" | head -n 1)
    
    local updated_timestamp=$(date +%s)
    
    local json_payload="{\"qd_id\":$record_id,\"sort_index\":$first_sortIndex,\"Timestamp\":$updated_timestamp}"
    
    local api_response=$(curl -X POST 'https://m.freecheck.cn/api/user/set_qd' \
        -H 'User-Agent: Mozilla/5.0 (Linux; Android 13; 23013RK75C Build/TKQ1.220905.001; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/116.0.0.0 Mobile Safari/537.36 XWEB/1160043 MMWEBSDK/20230805 MMWEBID/2038 MicroMessenger/8.0.42.2424(0x28002A43) WeChat/arm64 Weixin GPVersion/1 NetType/WIFI Language/zh_CN ABI/arm64' \
        -H "Content-Type: application/json; charset=UTF-8" \
        -H "userid: $USERID_1" \
        -H "token: $TOKEN_1" \
        -d "$json_payload" \
        -s) 
    
    # 将通知添加到数组
    NOTIFICATIONS+=("$user_note ($userid)，$api_response
")
    
    # Increment the user counter
    ((USER_COUNT++))

    # 如果是最后一个用户，等待2到3秒后发送通知
    if [ "$USER_COUNT" -eq "$TOTAL_USERS" ]; then
        echo "所有用户操作已完成，等待2到3秒后发送通知..."
        random_wait 2 3
        
        # 构造通知内容
        NOTIFICATION_CONTENT=$(IFS=$'\n'; echo "${NOTIFICATIONS[*]}")

        # 推送通知
        pushplus_notification "签到通知" "$NOTIFICATION_CONTENT"
    else
        # 如果不是最后一个用户，随机等待10到20秒
        echo "等待10到20秒后继续下一个用户操作..."
        random_wait 10 20
    fi
}

# 执行所有用户操作
execute_user_operations "$USERID_1" "$TOKEN_1" "大号"
execute_user_operations "$USERID_2" "$TOKEN_2" "小号"
