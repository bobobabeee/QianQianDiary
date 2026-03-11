# -*- coding: utf-8 -*-
"""
认证模块：发送验证码、注册、登录（密码/验证码）、重置密码、刷新 Token
所有接口无需登录
"""
import logging
from flask import Blueprint, request

from extensions import db
from models.user import User
from utils.response import ok, fail
from utils.jwt_helper import create_access_token, create_refresh_token, decode_token
from utils.validators import valid_phone

auth_bp = Blueprint("auth", __name__, url_prefix="/api/v1/auth")

# 开发阶段验证码存储（生产接入短信服务）
_sms_store = {}


def _get_code(phone: str) -> str:
    return _sms_store.get(phone.strip(), "")


def _set_code(phone: str, code: str) -> None:
    _sms_store[phone.strip()] = code


@auth_bp.route("/sms/send", methods=["POST"])
def send_sms():
    data = request.get_json() or {}
    phone = (data.get("phone") or "").strip()
    if not valid_phone(phone):
        return fail(400, "请输入正确的手机号", None)
    _set_code(phone, "123456")
    logging.info("sms send phone=%s code=123456 (dev)", phone[:7] + "****")
    return ok("验证码发送成功", None)


@auth_bp.route("/register", methods=["POST"])
def register():
    data = request.get_json() or {}
    phone = (data.get("phone") or "").strip()
    sms_code = (data.get("sms_code") or "").strip()
    password = (data.get("password") or "").strip()

    if not valid_phone(phone):
        return fail(400, "请输入正确的手机号", None)
    if len(sms_code) < 4:
        return fail(400, "请输入验证码", None)
    if len(password) < 6:
        return fail(400, "密码至少6位", None)

    if _get_code(phone) != sms_code:
        return fail(400, "验证码错误或已过期", None)
    if User.query.filter_by(phone=phone).first():
        return fail(400, "该手机号已注册", None)

    user = User(phone=phone)
    user.set_password(password)
    db.session.add(user)
    db.session.commit()
    logging.info("register user_id=%s phone=%s", user.id, phone[:7] + "****")

    token = create_access_token(user.id, phone)
    refresh = create_refresh_token(user.id, phone)
    return ok("success", {"user_id": user.id, "token": token, "refresh_token": refresh})


@auth_bp.route("/login", methods=["POST"])
def login():
    data = request.get_json() or {}
    phone = (data.get("phone") or "").strip()
    password = (data.get("password") or "").strip()

    if not valid_phone(phone):
        return fail(400, "请输入正确的手机号", None)
    if not password:
        return fail(400, "请输入密码", None)

    user = User.query.filter_by(phone=phone).first()
    if not user or not user.check_password(password):
        return fail(401, "手机号或密码错误", None)
    logging.info("login user_id=%s", user.id)

    token = create_access_token(user.id, phone)
    refresh = create_refresh_token(user.id, phone)
    return ok("success", {"user_id": user.id, "token": token, "refresh_token": refresh})


@auth_bp.route("/login/sms", methods=["POST"])
def login_sms():
    data = request.get_json() or {}
    phone = (data.get("phone") or "").strip()
    sms_code = (data.get("sms_code") or "").strip()

    if not valid_phone(phone):
        return fail(400, "请输入正确的手机号", None)
    if len(sms_code) < 4:
        return fail(400, "请输入验证码", None)
    if _get_code(phone) != sms_code:
        return fail(401, "验证码错误或已过期", None)

    user = User.query.filter_by(phone=phone).first()
    if not user:
        return fail(401, "该手机号未注册", None)
    logging.info("login_sms user_id=%s", user.id)

    token = create_access_token(user.id, phone)
    refresh = create_refresh_token(user.id, phone)
    return ok("success", {"user_id": user.id, "token": token, "refresh_token": refresh})


@auth_bp.route("/password/reset", methods=["POST"])
def reset_password():
    data = request.get_json() or {}
    phone = (data.get("phone") or "").strip()
    sms_code = (data.get("sms_code") or "").strip()
    new_password = (data.get("new_password") or "").strip()

    if not valid_phone(phone):
        return fail(400, "请输入正确的手机号", None)
    if len(sms_code) < 4:
        return fail(400, "请输入验证码", None)
    if len(new_password) < 6:
        return fail(400, "新密码至少6位", None)
    if _get_code(phone) != sms_code:
        return fail(401, "验证码错误或已过期", None)

    user = User.query.filter_by(phone=phone).first()
    if not user:
        return fail(404, "该手机号未注册", None)

    user.set_password(new_password)
    db.session.commit()
    logging.info("password reset user_id=%s", user.id)
    return ok("密码重置成功", None)


@auth_bp.route("/refresh", methods=["POST"])
def refresh():
    """刷新 Token：用 refresh_token 换新的 access_token 和 refresh_token"""
    data = request.get_json() or {}
    refresh_token = (data.get("refresh_token") or "").strip()
    if not refresh_token:
        return fail(401, "未登录或token已过期", None)

    payload = decode_token(refresh_token)
    if not payload or payload.get("type") != "refresh":
        return fail(401, "未登录或token已过期", None)

    user_id = payload.get("user_id") or payload.get("sub")
    phone = payload.get("phone") or ""
    user = User.query.get(user_id)
    if not user:
        return fail(401, "用户不存在", None)

    token = create_access_token(user.id, user.phone)
    new_refresh = create_refresh_token(user.id, user.phone)
    return ok("success", {"user_id": user.id, "token": token, "refresh_token": new_refresh})
