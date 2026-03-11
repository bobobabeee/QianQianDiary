# 真实 API 接入指南

接入真实后端需要做两件事：**后端提供接口** + **App 里调用接口**。下面按顺序说明。

---

## 一、后端需要提供哪些接口

### 1. 认证相关（必做）

| 用途     | 建议方法 | 路径示例       | 请求体示例 | 成功时返回 |
|----------|----------|----------------|------------|------------|
| 发送验证码 | POST | `/auth/sms/send` | `{"phone":"13800138000"}` | 200 空或 `{"message":"ok"}` |
| 密码登录   | POST | `/auth/login`    | `{"phone":"13800138000","password":"xxx"}` | 200 + `{"token":"xxx","phone":"13800138000"}` 或仅 token |
| 验证码登录 | POST | `/auth/login/sms` | `{"phone":"13800138000","code":"123456"}`  | 同上 |
| 注册       | POST | `/auth/register` | `{"phone":"13800138000","code":"123456","password":"xxx"}` | 200 + token（或仅成功） |
| 重置密码   | POST | `/auth/password/reset` | `{"phone":"13800138000","code":"123456","new_password":"xxx"}` | 200 空 |

- 所有需要「已登录」的接口，请求头带：`Authorization: Bearer <token>`。
- 未登录或 token 无效时返回 **401**，App 会提示重新登录。

### 2. 数据同步（可选：换设备可看到数据）

若希望日记/美德/愿景在换设备或重装后仍存在，后端需要按用户存储并提供接口，例如：

| 数据   | 建议接口 | 说明 |
|--------|----------|------|
| 成功日记 | `GET/POST/PUT/DELETE /api/diary/entries` | 列表 GET，单条增删改 POST/PUT/DELETE |
| 美德践行 | `GET/POST/PUT /api/virtue/logs` | 同上 |
| 愿景板   | `GET/POST/PUT/DELETE /api/vision/items` | 同上 |

当前 App 已支持**按用户本地持久化**；接入 API 后可在每次启动或定时拉取接口数据、与本地合并，写回时先写本地再上报接口。

---

## 二、App 端要做的修改

### 1. 配置 Base URL

在 **`Sources/Services/APIConfig.swift`** 里把 `baseURL` 改成你的后端地址，例如：

```swift
static var baseURL: String {
    #if DEBUG
    return "https://your-real-api.com"  // 或开发环境地址
    #else
    return "https://your-real-api.com"
    #endif
}
```

调试时也可用环境变量：在 Xcode Scheme 里加 `API_BASE_URL = https://...`。

### 2. 认证：用真实接口替换 AuthService 里的模拟逻辑

- 已提供 **`APIClient`**：支持 `requestVoid(path:method:body:completion:)` 和 `request(path:method:body:completion:)`，自动带 `Authorization: Bearer <token>`（token 来自当前登录态）。
- 在 **`AuthService`** 中：
  - **登录/注册成功**：从响应里取出 `token`（和可选 `phone`），调用现有 `saveSession(phone:token:)` 保存；同时可设置 `APIClient.shared.authToken = token`，以便后续请求带 token。
  - **发送验证码**：调用 `APIClient.shared.requestVoid(path: "/auth/sms/send", method: "POST", body: ["phone": phone], completion: ...)`（请求体字段名与后端约定一致）。
  - **密码登录**：`request(path: "/auth/login", method: "POST", body: LoginRequest(phone:phone, password:password))`，在 completion 里解析 token 并 `saveSession` + 设置 `APIClient.shared.authToken`。
  - **验证码登录 / 注册 / 重置密码**：同理，用对应 path 和 body，成功后再决定是否保存 session。

请求/响应模型建议与后端约定一致（如 snake_case 字段名，`APIClient` 已用 `convertFromSnakeCase` / `convertToSnakeCase`）。

### 3. 安全建议

- 全部使用 **HTTPS**。
- Token 建议存 **Keychain**，不要长期放在 UserDefaults；当前为简化先放在 UserDefaults，上线前可改为 Keychain。
- 密码、验证码不要打日志，也不要写死在任何配置里。

### 4. 错误与提示

- `APIClient` 已把 401 转成「登录已过期，请重新登录」、5xx 转成「服务器繁忙，请稍后重试」；其他 4xx 可解析后端返回的 `message` 或 `error` 字段（见 `APIError.serverMessage`）。
- 在登录/注册/重置页的 completion 里，把 `Result.failure` 转成 `errorMessage` 展示即可（与当前 UI 一致）。

---

## 三、接口约定示例（与后端对齐）

### 发送验证码

- **POST** `/auth/sms/send`
- Request: `{ "phone": "13800138000" }`
- Response: 200 无体或 `{ "message": "ok" }`

### 密码登录

- **POST** `/auth/login`
- Request: `{ "phone": "13800138000", "password": "your_password" }`
- Response: `{ "token": "jwt_or_opaque_string", "phone": "13800138000" }`

### 验证码登录

- **POST** `/auth/login/sms`
- Request: `{ "phone": "13800138000", "code": "123456" }`
- Response: 同密码登录

### 注册

- **POST** `/auth/register`
- Request: `{ "phone": "13800138000", "code": "123456", "password": "new_password" }`
- Response: 200 + 可选 token（若后端直接登录则带 token）

### 重置密码

- **POST** `/auth/password/reset`
- Request: `{ "phone": "13800138000", "code": "123456", "new_password": "xxx" }`
- Response: 200 空

---

## 四、小结

1. **后端**：按上表实现认证接口（必做），如需多端同步再实现日记/美德/愿景的 CRUD。
2. **App**：改 `APIConfig.baseURL`，在 `AuthService` 里用 `APIClient` 替换所有 `DispatchQueue.main.asyncAfter` 的模拟逻辑，登录/注册成功时保存 token 并设置 `APIClient.shared.authToken`。
3. **安全**：HTTPS、token 存 Keychain、不记录敏感信息。

项目里已包含 **`APIClient`**、**`APIConfig`**，可直接在此基础上对接你的真实 API。
