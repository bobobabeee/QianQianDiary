#!/bin/bash
# 接口测试脚本：按顺序测试 健康检查 → 注册 → 登录 → 创建日记 → 查看日记
# 前提：python app.py 已启动在 5001 端口

BASE="http://localhost:5001"
PHONE="13800138000"
PASSWORD="test123456"
CODE="123456"

echo "===== 1. 健康检查 ====="
curl -s "$BASE/health" | python3 -m json.tool
echo ""

echo "===== 2. 发送验证码 ====="
curl -s -X POST "$BASE/api/v1/auth/sms/send" \
  -H "Content-Type: application/json" \
  -d "{\"phone\":\"$PHONE\"}" | python3 -m json.tool
echo ""

echo "===== 3. 注册（开发环境验证码固定 123456）====="
REG=$(curl -s -X POST "$BASE/api/v1/auth/register" \
  -H "Content-Type: application/json" \
  -d "{\"phone\":\"$PHONE\",\"sms_code\":\"$CODE\",\"password\":\"$PASSWORD\"}")
echo "$REG" | python3 -m json.tool

# 从注册响应取出 token（若已注册过则用登录）
TOKEN=$(echo "$REG" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',{}).get('token',''))" 2>/dev/null)
if [ -z "$TOKEN" ]; then
  echo "（若已注册，改为登录）"
  LOGIN=$(curl -s -X POST "$BASE/api/v1/auth/login" \
    -H "Content-Type: application/json" \
    -d "{\"phone\":\"$PHONE\",\"password\":\"$PASSWORD\"}")
  echo "$LOGIN" | python3 -m json.tool
  TOKEN=$(echo "$LOGIN" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('data',{}).get('token',''))" 2>/dev/null)
fi

if [ -z "$TOKEN" ]; then
  echo "无法获取 token，请检查注册/登录接口"
  exit 1
fi
echo ""
echo "Token 已获取，后续请求将带上 Authorization"
echo ""

echo "===== 4. 创建一条成功日记 ====="
CREATE=$(curl -s -X POST "$BASE/api/v1/diary/entries" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"content":"今天早起完成了晨跑，感觉很有活力！","date":"2026-03-10","category":"health","mood_icon":"Sun"}')
echo "$CREATE" | python3 -m json.tool
echo ""

echo "===== 5. 查看日记列表 ====="
curl -s "$BASE/api/v1/diary/entries?page=1&page_size=10" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
echo ""
echo "===== 测试完成 ====="
