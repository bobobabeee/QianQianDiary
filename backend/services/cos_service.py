# -*- coding: utf-8 -*-
"""
腾讯云 COS 图片上传服务
将客户端上传的图片写入 COS，返回可访问的 URL
"""
import uuid
from flask import current_app


# 允许的图片扩展名
ALLOWED_EXTENSIONS = {"jpg", "jpeg", "png", "gif", "webp"}

# 愿景板图片存储路径前缀
VISION_PREFIX = "vision"


def allowed_file(filename: str) -> bool:
    if not filename or "." not in filename:
        return False
    ext = filename.rsplit(".", 1)[1].lower()
    return ext in ALLOWED_EXTENSIONS


def upload_vision_image(file_stream, filename: str) -> str | None:
    """
    上传愿景板图片到 COS
    :param file_stream: 文件流（如 request.files["file"].stream）
    :param filename: 原始文件名，用于取扩展名
    :return: 可访问的图片 URL，失败返回 None
    """
    secret_id = current_app.config.get("COS_SECRET_ID")
    secret_key = current_app.config.get("COS_SECRET_KEY")
    bucket = current_app.config.get("COS_BUCKET")
    region = current_app.config.get("COS_REGION", "ap-shanghai")
    domain = current_app.config.get("COS_DOMAIN", "").rstrip("/")

    if not all([secret_id, secret_key, bucket]):
        return None

    if not allowed_file(filename):
        return None

    try:
        from qcloud_cos import CosConfig, CosS3Client
    except ImportError:
        return None

    ext = filename.rsplit(".", 1)[1].lower()
    key = f"{VISION_PREFIX}/{uuid.uuid4().hex}.{ext}"

    config = CosConfig(Region=region, SecretId=secret_id, SecretKey=secret_key)
    client = CosS3Client(config)

    # put_object 支持 file-like 对象
    client.put_object(
        Bucket=bucket,
        Body=file_stream,
        Key=key,
        ContentType=f"image/{ext}" if ext != "jpg" else "image/jpeg",
    )

    if domain:
        return f"{domain}/{key}"
    return f"https://{bucket}.cos.{region}.myqcloud.com/{key}"
