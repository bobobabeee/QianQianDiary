# Qianqian Diary 后端 API

基于 Flask + MySQL，接口统一前缀 `/api/v1`，JWT 鉴权。

## 一、环境要求

- Python 3.9+
- MySQL 5.7+

## 二、数据库建表

执行 SQL 或使用 `init_db.py` 自动建表：

```sql
CREATE DATABASE qianqian_diary CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'qianqian'@'localhost' IDENTIFIED BY '你的密码';
GRANT ALL PRIVILEGES ON qianqian_diary.* TO 'qianqian'@'localhost';
FLUSH PRIVILEGES;
```

## 三、环境变量（敏感信息禁止硬编码）

| 变量 | 说明 |
|------|------|
| MYSQL_HOST | 数据库地址，默认 localhost |
| MYSQL_PORT | 3306 |
| MYSQL_USER | 用户名 |
| MYSQL_PASSWORD | 密码 |
| MYSQL_DATABASE | 库名 qianqian_diary |
| SECRET_KEY | 应用密钥 |
| JWT_SECRET_KEY | JWT 密钥 |
| COS_SECRET_ID / COS_SECRET_KEY / COS_BUCKET | 腾讯云 COS（愿景板图片） |
| CORS_ORIGINS | 跨域域名，默认 http://localhost:3000 |

## 四、本地运行

```bash
cd backend
pip install -r requirements.txt
export MYSQL_PASSWORD=你的密码  # 或写入 .env
python init_db.py
python app.py
```

服务默认在 `http://0.0.0.0:5001`。

## 五、接口一览

### 认证（无需登录）

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | /api/v1/auth/sms/send | 发送验证码 |
| POST | /api/v1/auth/register | 注册 |
| POST | /api/v1/auth/login | 密码登录 |
| POST | /api/v1/auth/login/sms | 验证码登录 |
| POST | /api/v1/auth/password/reset | 重置密码 |
| POST | /api/v1/auth/refresh | 刷新 Token |

### 成功日记（需登录）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/v1/diary/entries | 列表 ?page&page_size&date&category |
| POST | /api/v1/diary/entries | 创建 |
| PUT | /api/v1/diary/entries/:id | 更新 |
| DELETE | /api/v1/diary/entries/:id | 删除 |

### 美德践行（需登录）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/v1/virtue/logs | 列表 ?date&start_date&end_date |
| POST | /api/v1/virtue/logs | 创建 |
| PUT | /api/v1/virtue/logs/:id | 更新 |
| DELETE | /api/v1/virtue/logs/:id | 删除 |

### 日历、统计（需登录）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/v1/calendar | ?start_date&end_date 每日 has_diary, virtue_completed |
| GET | /api/v1/stats/virtue | ?start_date&end_date 美德分布、完成率 |

### 愿景板（需登录）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | /api/v1/vision/items | 列表 ?category |
| POST | /api/v1/vision/items | 创建 |
| PUT | /api/v1/vision/items/:id | 更新 |
| DELETE | /api/v1/vision/items/:id | 删除 |
| POST | /api/v1/vision/upload | 上传图片到 COS |

## 六、统一返回格式

```json
{ "code": 200, "msg": "success", "data": {} }
```

- 200 成功 / 400 参数错误 / 401 未登录 / 403 无权限 / 404 不存在 / 500 服务器错误
