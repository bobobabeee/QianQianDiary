# -*- coding: utf-8 -*-
"""JWT Access Token + Refresh Token"""
import time
import jwt
from flask import current_app


def create_access_token(user_id: int, phone: str) -> str:
    now = int(time.time())
    payload = {
        "sub": user_id,
        "phone": phone,
        "user_id": user_id,
        "type": "access",
        "iat": now,
        "exp": now + current_app.config["JWT_ACCESS_EXPIRE_HOURS"] * 3600,
    }
    return jwt.encode(payload, current_app.config["JWT_SECRET_KEY"], algorithm="HS256")


def create_refresh_token(user_id: int, phone: str) -> str:
    now = int(time.time())
    payload = {
        "sub": user_id,
        "phone": phone,
        "user_id": user_id,
        "type": "refresh",
        "iat": now,
        "exp": now + current_app.config["JWT_REFRESH_EXPIRE_DAYS"] * 86400,
    }
    return jwt.encode(payload, current_app.config["JWT_SECRET_KEY"], algorithm="HS256")


def decode_token(token: str) -> dict | None:
    if not token:
        return None
    try:
        return jwt.decode(
            token, current_app.config["JWT_SECRET_KEY"], algorithms=["HS256"]
        )
    except (jwt.ExpiredSignatureError, jwt.InvalidTokenError):
        return None
