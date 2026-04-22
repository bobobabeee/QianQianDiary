# 闪光时刻 — 前端对接 API 文档

> **Base URL**: `http://<host>:5001`  
> **鉴权**: 除登录/注册外，请求头需携带 `Authorization: Bearer <token>`  
> **Content-Type**: `application/json`（除上传接口外）

---

## 一、统一响应格式

```json
{
  "code": 200,
  "message": "success",
  "data": { ... }
}
```

| code | 含义 |
|------|------|
| 200 | 成功 |
| 400 | 参数错误 |
| 401 | 未登录 / Token 过期 |
| 404 | 资源不存在 |
| 409 | 冲突（如用户名已存在） |

失败时 `data` 可能为 `null`。

---

## 二、认证模块 `/api/auth`

### 2.1 用户注册

```
POST /api/auth/regist
```

**请求体：**
```json
{
  "username": "zhangsan",
  "password": "abc123",
  "header": "https://example.com/avatar.png"  // 可选
}
```

**成功响应：**
```json
{
  "code": 200,
  "message": "注册成功",
  "data": {
    "id": 1,
    "username": "zhangsan",
    "header": null
  }
}
```

**失败：** `400` 用户名已存在

---

### 2.2 用户登录

```
POST /api/auth/login
```

**请求体：**
```json
{
  "username": "zhangsan",
  "password": "abc123"
}
```

**成功响应：**
```json
{
  "code": 200,
  "message": "登录成功",
  "data": {
    "token": "eyJhbGciOi...",
    "user": {
      "id": 1,
      "username": "zhangsan",
      "header": null
    }
  }
}
```

**失败：** `400` 用户名/密码不能为空、用户和密码不匹配

---

### 2.3 发送短信验证码

```
POST /auth/sms/send
```

**请求体：**
```json
{
  "phone": "13800138000"
}
```

**成功响应：**
返回 `2xx` 即视为成功（前端不会解析响应体；可返回空体或统一响应包装）。

---

### 2.4 短信验证码登录

```
POST /auth/login/sms
```

**请求体：**
```json
{
  "phone": "13800138000",
  "code": "1234"
}
```

**成功响应：**（此接口返回体**不带** `code/message/data` 包装）
```json
{
  "token": "eyJhbGciOi...",
  "phone": "13800138000"
}
```

**失败：** `400` 手机号/验证码无效

---

### 2.5 重置密码

```
POST /auth/password/reset
```

**请求体：**
```json
{
  "phone": "13800138000",
  "code": "1234",
  "new_password": "newPassword123"
}
```

**成功响应：**
返回 `2xx` 即视为成功（前端不会解析响应体；可返回空体或统一响应包装）。

## 三、成功日记模块 `/api/diary`（需鉴权）

### 3.1 获取日记列表

```
GET /api/diary/entries?date=2026-03-19&category=DAILY&page=1&page_size=20
```

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| date | string | 否 | 日期 `yyyy-MM-dd` |
| category | string | 否 | WORK / HEALTH / RELATIONSHIP / GROWTH / DAILY |
| page | int | 否 | 默认 1 |
| page_size | int | 否 | 默认 20，最大 50 |

**成功响应：**
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "total": 42,
    "page": 1,
    "page_size": 20,
    "items": [
      {
        "id": "uuid-string",
        "date": "2026-03-19",
        "content": "日记内容...",
        "category": "DAILY",
        "mood_icon": "Sun"
      }
    ]
  }
}
```

---

### 3.2 获取单条日记

```
GET /api/diary/entries/{id}
```

**成功响应：**
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": "uuid-string",
    "date": "2026-03-19",
    "content": "日记内容...",
    "category": "DAILY",
    "mood_icon": "Sun"
  }
}
```

**失败：** `404` 日记不存在

---

### 3.3 创建日记

```
POST /api/diary/entries
```

**请求体：**
```json
{
  "date": "2026-03-19",
  "content": "日记内容，5~500字符",
  "category": "DAILY",
  "mood_icon": "Sun"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| date | string | 否 | 默认当天 |
| content | string | 是 | 5~500 字符 |
| category | string | 否 | 默认 DAILY |
| mood_icon | string | 否 | 默认 Sun |

**成功响应：** `data` 为新建日记对象

**失败：** `400` 内容不足 5 字、超过 500 字、日期格式错误、无效分类

---

### 3.4 更新日记

```
PUT /api/diary/entries/{id}
```

**请求体（只传需修改的字段）：**
```json
{
  "date": "2026-03-19",
  "content": "更新后的内容",
  "category": "GROWTH",
  "mood_icon": "Zap"
}
```

**成功响应：** `data` 为更新后的日记对象

**失败：** `404` 日记不存在；`400` 内容/日期/分类校验失败

---

### 3.5 删除日记

```
DELETE /api/diary/entries/{id}
```

**成功响应：**
```json
{
  "code": 200,
  "message": "删除成功",
  "data": null
}
```

---

### 3.6 日记统计

```
GET /api/diary/stats?start_date=2026-03-01&end_date=2026-03-31&category=DAILY
```

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| start_date | string | 否 | 起始日期 |
| end_date | string | 否 | 结束日期 |
| category | string | 否 | 按分类 |

**成功响应：**
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "total_count": 42,
    "this_week_count": 5,
    "top_category": "DAILY",
    "streak_days": 7,
    "category_distribution": [
      { "category": "DAILY", "count": 15, "label": "日常微光" },
      { "category": "WORK", "count": 10, "label": "职业成就" }
    ]
  }
}
```

---

### 3.7 日历有记录日期

```
GET /api/diary/calendar?year=2026&month=3
```

| 参数 | 类型 | 必填 |
|------|------|------|
| year | int | 是 |
| month | int | 是 (1-12) |

**成功响应：**
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "year": 2026,
    "month": 3,
    "recorded_dates": ["2026-03-01", "2026-03-05", "2026-03-19"]
  }
}
```

---

### 3.8 首页高光时刻

```
GET /api/diary/highlights?limit=3
```

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| limit | int | 否 | 默认 3 |

**成功响应：**
```json
{
  "code": 200,
  "message": "success",
  "data": [
    {
      "id": "uuid-string",
      "date": "2026-03-19",
      "display_date": "今天",
      "content": "日记内容...",
      "category": "DAILY",
      "category_label": "日常微光",
      "category_color": "#FFF2D1",
      "mood_icon": "Sun"
    }
  ]
}
```

---

## 四、美德践行模块 `/api/virtue`（需鉴权）

### 4.1 获取美德定义列表

```
GET /api/virtue/definitions
```

**成功响应：**
```json
{
  "code": 200,
  "message": "success",
  "data": [
    {
      "id": "virtue-friendly",
      "type": "FRIENDLY",
      "name": "友好亲和",
      "quote": "最美好的事情莫过于温和待人。",
      "guidelines": ["祝愿他人生活幸福", "..."],
      "icon_name": "Smile"
    }
  ]
}
```

---

### 4.2 获取今日美德

```
GET /api/virtue/today?date=2026-03-19
```

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| date | string | 否 | 默认今天 |

**成功响应：**
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "definition": {
      "id": "virtue-friendly",
      "type": "FRIENDLY",
      "name": "友好亲和",
      "quote": "...",
      "guidelines": ["..."],
      "icon_name": "Smile"
    },
    "practice_log": {
      "id": "log-uuid 或 null",
      "date": "2026-03-19",
      "virtue_type": "FRIENDLY",
      "is_completed": false,
      "reflection": ""
    }
  }
}
```

---

### 4.3 获取践行记录列表

```
GET /api/virtue/logs?date=2026-03-19&virtue_type=FRIENDLY&page=1&page_size=20
```

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| date | string | 否 | 日期筛选 |
| virtue_type | string | 否 | 美德类型 |
| page | int | 否 | 默认 1 |
| page_size | int | 否 | 默认 20 |

**成功响应：**
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "total": 30,
    "page": 1,
    "page_size": 20,
    "items": [
      {
        "id": "log-uuid",
        "date": "2026-03-19",
        "virtue_type": "FRIENDLY",
        "is_completed": true,
        "reflection": "践行感悟..."
      }
    ]
  }
}
```

---

### 4.4 提交/更新践行记录（同一天同类型 upsert）

```
POST /api/virtue/logs
```

**请求体：**
```json
{
  "date": "2026-03-19",
  "virtue_type": "FRIENDLY",
  "is_completed": true,
  "reflection": "践行感悟..."
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| date | string | 否 | 默认今天 |
| virtue_type | string | 是 | FRIENDLY/RESPONSIBLE/KIND/HELPFUL/GRATEFUL/LEARNING/RELIABLE |
| is_completed | bool | 否 | 默认 false |
| reflection | string | 否 | 践行感悟 |

**成功响应：** `data` 为保存后的记录对象

---

### 4.5 美德成长统计

```
GET /api/virtue/stats
```

**成功响应：**
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "total_practices": 30,
    "virtues_covered": 5,
    "streak_days": 7,
    "type_distribution": [
      { "virtue_type": "FRIENDLY", "count": 8, "name": "友好亲和" }
    ]
  }
}
```

---

## 五、愿景板模块 `/api/vision`（需鉴权）

### 5.1 获取愿景列表

```
GET /api/vision/items?category=WORK
```

| 参数 | 类型 | 必填 |
|------|------|------|
| category | string | 否 |

**成功响应：**
```json
{
  "code": 200,
  "message": "success",
  "data": [
    {
      "id": "uuid-string",
      "category": "WORK",
      "title": "愿景标题",
      "description": "描述",
      "image_url": "https://...",
      "target_date": "2026-12-31"
    }
  ]
}
```

---

### 5.2 获取单个愿景

```
GET /api/vision/items/{id}
```

**成功响应：** `data` 为单个愿景对象

**失败：** `404` 愿景不存在

---

### 5.3 创建愿景

```
POST /api/vision/items
```

**请求体：**
```json
{
  "category": "WORK",
  "title": "愿景标题",
  "description": "描述",
  "image_url": "https://...",
  "target_date": "2026-12-31"
}
```

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| category | string | 否 | 默认 GROWTH |
| title | string | 否 | 默认空 |
| description | string | 否 | 默认空 |
| image_url | string | 否 | 默认空 |
| target_date | string | 否 | `yyyy-MM-dd` |

---

### 5.4 更新愿景

```
PUT /api/vision/items/{id}
```

**请求体（只传需修改的字段）：**
```json
{
  "category": "GROWTH",
  "title": "新标题",
  "description": "新描述",
  "image_url": "https://...",
  "target_date": "2027-06-30"
}
```

---

### 5.5 删除愿景

```
DELETE /api/vision/items/{id}
```

**成功响应：** `data: null`

---

## 六、用户信息模块 `/api/user`（需鉴权）

### 6.1 获取当前用户信息

```
GET /api/user/profile
```

**成功响应：**
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "id": 1,
    "username": "zhangsan",
    "header": "https://example.com/avatar.png"
  }
}
```

---

### 6.2 更新用户信息

```
PUT /api/user/profile
```

**请求体：**
```json
{
  "username": "zhangsan_new",
  "header": "https://example.com/new-avatar.png"
}
```

两个字段均为可选，传则更新。

**成功响应：** `data` 为更新后的用户对象

**失败：** `409` 用户名已存在

---

### 6.3 修改密码

```
POST /api/user/change-password
```

**请求体：**
```json
{
  "old_password": "旧密码",
  "new_password": "新密码，≥6位"
}
```

**成功响应：** `data: null`

**失败：** `401` 旧密码不正确；`400` 新密码少于 6 位

---

## 七、图片上传（待实现）

```
POST /api/upload/image
Content-Type: multipart/form-data
```

| 字段 | 说明 |
|------|------|
| file | 图片文件 (JPEG/PNG，≤5MB) |
| type | 可选：vision / avatar |

**期望成功响应：**
```json
{
  "code": 200,
  "message": "上传成功",
  "data": { "url": "https://cdn.example.com/xxx.png" }
}
```

> 注：当前后端未实现该接口，前端可预留调用逻辑。

---

## 八、枚举值速查

### 日记/愿景分类
| 值 | 中文 |
|----|------|
| WORK | 职业成就 |
| HEALTH | 身体健康 |
| RELATIONSHIP | 人际关系 |
| GROWTH | 个人成长 |
| DAILY | 日常微光 |

### 美德类型
| 值 | 中文 |
|----|------|
| FRIENDLY | 友好亲和 |
| RESPONSIBLE | 勇于承担 |
| KIND | 善待他人 |
| HELPFUL | 帮助给予 |
| GRATEFUL | 感恩之心 |
| LEARNING | 勤学不辍 |
| RELIABLE | 值得信赖 |

### 心情图标（示例）
Sun / Zap / Activity / MessageSquareHeart / Heart / Star / BookOpen / Briefcase / Users

---

## 九、cURL 调试示例

```bash
# 登录
TOKEN=$(curl -s -X POST http://localhost:5001/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"test","password":"123456"}' | jq -r '.data.token')

# 带 Token 请求
curl -X GET "http://localhost:5001/api/diary/entries?page=1&page_size=10" \
  -H "Authorization: Bearer $TOKEN"
```
