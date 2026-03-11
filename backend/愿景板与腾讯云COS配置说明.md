# 愿景板 + 腾讯云 COS 配置说明

## 一、功能说明

- **愿景板**：增删改查（`/api/v1/vision/items`）
- **图片上传**：`POST /api/v1/vision/upload`，上传到腾讯云 COS 后返回 URL

## 二、环境变量（必须配置才能上传图片）

| 变量 | 说明 | 示例 |
|------|------|------|
| `COS_SECRET_ID` | 腾讯云 API 密钥 SecretId | 在腾讯云控制台 → 访问管理 → API 密钥 创建 |
| `COS_SECRET_KEY` | 腾讯云 API 密钥 SecretKey | 同上 |
| `COS_BUCKET` | 存储桶名称（含 appid） | `mybucket-1234567890` |
| `COS_REGION` | 地域 | `ap-shanghai` / `ap-guangzhou` |
| `COS_DOMAIN` | 可选，自定义域名 | `https://cdn.example.com` |

## 三、腾讯云 COS 开通步骤

1. 登录 [腾讯云控制台](https://console.cloud.tencent.com/)
2. 搜索「对象存储 COS」→ 创建存储桶
3. 选择地域（如 `ap-shanghai`）、访问权限建议选「私有读写」或「公有读私有写」（图片需可访问）
4. 在「访问管理 → API 密钥」创建密钥，得到 `SecretId` 和 `SecretKey`
5. 存储桶 → 权限管理 → 为子账号或当前账号授予 PutObject 等权限

## 四、本地测试

若未配置 COS，上传接口会返回 `500 图片上传失败`。可先：

- 创建 / 更新愿景时直接传 `image_url`（如 `asset:vision_work` 或任意 URL）
- 配置好 COS 后再用 `/api/v1/vision/upload` 上传图片

## 五、接口一览

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/v1/vision/items` | 列表（可选 ?category=work） |
| POST | `/api/v1/vision/items` | 创建 |
| PUT | `/api/v1/vision/items/:id` | 更新 |
| DELETE | `/api/v1/vision/items/:id` | 删除 |
| POST | `/api/v1/vision/upload` | 上传图片，multipart/form-data，字段 `file` |

所有接口需在请求头带上：`Authorization: Bearer <token>`
