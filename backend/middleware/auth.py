# -*- coding: utf-8 -*-
"""鉴权：从 Authorization: Bearer <token> 解析 user_id"""
from functools import wraps
from flask import request
from utils.response import fail
from utils.jwt_helper import decode_token


def get_current_user_id() -> int | None:
    auth = request.headers.get("Authorization")
    if not auth or not auth.startswith("Bearer "):
        return None
    token = auth[7:].strip()
    payload = decode_token(token)
    if not payload or payload.get("type") != "access":
        return None
    return payload.get("user_id") or payload.get("sub")


def require_auth(f):
    @wraps(f)
    def wrapped(*args, **kwargs):
        user_id = get_current_user_id()
        if not user_id:
            return fail(401, "未登录或token已过期", None)
        return f(user_id=user_id, *args, **kwargs)

    return wrapped
