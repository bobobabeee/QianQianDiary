# -*- coding: utf-8 -*-
"""
应用配置：仅从环境变量或默认值读取，禁止硬编码敏感信息
"""
import os
from datetime import timedelta


class Config:
    """基础配置"""
    SECRET_KEY = os.environ.get("SECRET_KEY", "dev-secret-change-in-production")
    JWT_SECRET_KEY = os.environ.get("JWT_SECRET_KEY", os.environ.get("SECRET_KEY", "dev-jwt-secret"))

    # MySQL（必须通过环境变量或 .env 配置生产环境）
    MYSQL_HOST = os.environ.get("MYSQL_HOST", "localhost")
    MYSQL_PORT = int(os.environ.get("MYSQL_PORT", "3306"))
    MYSQL_USER = os.environ.get("MYSQL_USER", "root")
    MYSQL_PASSWORD = os.environ.get("MYSQL_PASSWORD", "")
    MYSQL_DATABASE = os.environ.get("MYSQL_DATABASE", "qianqian_diary")

    @staticmethod
    def get_sqlalchemy_uri():
        c = Config
        return (
            f"mysql+pymysql://{c.MYSQL_USER}:{c.MYSQL_PASSWORD}"
            f"@{c.MYSQL_HOST}:{c.MYSQL_PORT}/{c.MYSQL_DATABASE}?charset=utf8mb4"
        )

    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # JWT：Access 1 小时，Refresh 7 天
    JWT_ACCESS_EXPIRE_HOURS = int(os.environ.get("JWT_ACCESS_EXPIRE_HOURS", "1"))
    JWT_REFRESH_EXPIRE_DAYS = int(os.environ.get("JWT_REFRESH_EXPIRE_DAYS", "7"))

    # CORS：允许本地前端
    CORS_ORIGINS = os.environ.get("CORS_ORIGINS", "http://localhost:3000")

    # 内容长度上限（字符）
    MAX_CONTENT_LENGTH = 2000

    # 腾讯云 COS 配置（图片存储，敏感信息必须用环境变量）
    COS_SECRET_ID = os.environ.get("COS_SECRET_ID", "")
    COS_SECRET_KEY = os.environ.get("COS_SECRET_KEY", "")
    COS_BUCKET = os.environ.get("COS_BUCKET", "")  # 如 mybucket-1234567890
    COS_REGION = os.environ.get("COS_REGION", "ap-shanghai")  # 地域
    COS_DOMAIN = os.environ.get("COS_DOMAIN", "")  # 自定义域名，为空则用默认 https://<bucket>.cos.<region>.myqcloud.com
