# -*- coding: utf-8 -*-
"""
美德践行模块：增删改查
"""
import logging
from flask import Blueprint, request

from extensions import db
from models.virtue_log import VirtueLog, VIRTUE_TYPES
from utils.response import ok, fail
from utils.validators import valid_date, valid_content
from middleware.auth import require_auth

virtue_bp = Blueprint("virtue", __name__, url_prefix="/api/v1/virtue")


@virtue_bp.route("/logs", methods=["GET"])
@require_auth
def list_logs(user_id):
    date_filter = request.args.get("date", "").strip()
    start_date = request.args.get("start_date", "").strip()
    end_date = request.args.get("end_date", "").strip()

    q = VirtueLog.query.filter(VirtueLog.user_id == user_id)
    if date_filter and valid_date(date_filter):
        q = q.filter(VirtueLog.date == date_filter)
    if start_date and valid_date(start_date):
        q = q.filter(VirtueLog.date >= start_date)
    if end_date and valid_date(end_date):
        q = q.filter(VirtueLog.date <= end_date)

    items = q.order_by(VirtueLog.date.desc(), VirtueLog.id.desc()).all()
    return ok("success", {"list": [i.to_dict() for i in items], "total": len(items)})


@virtue_bp.route("/logs", methods=["POST"])
@require_auth
def create_log(user_id):
    data = request.get_json() or {}
    virtue_type = (data.get("virtue_type") or "").strip()
    completed = data.get("completed", True)
    reflection = (data.get("reflection") or "").strip()
    date_str = (data.get("date") or "").strip()

    if virtue_type not in VIRTUE_TYPES:
        return fail(400, "无效的美德类型", None)
    if not valid_date(date_str):
        return fail(400, "日期格式为 yyyy-MM-dd", None)
    if not valid_content(reflection):
        return fail(400, "感想超过2000字", None)

    # 同一天同类型只保留一条
    existing = VirtueLog.query.filter(
        VirtueLog.user_id == user_id,
        VirtueLog.date == date_str,
        VirtueLog.virtue_type == virtue_type,
    ).first()
    if existing:
        existing.completed = bool(completed)
        existing.reflection = reflection
        db.session.commit()
        logging.info("virtue update user_id=%s id=%s", user_id, existing.id)
        return ok("success", {"id": existing.id})

    log = VirtueLog(user_id=user_id, virtue_type=virtue_type, completed=bool(completed), reflection=reflection, date=date_str)
    db.session.add(log)
    db.session.commit()
    logging.info("virtue create user_id=%s id=%s", user_id, log.id)
    return ok("success", {"id": log.id})


@virtue_bp.route("/logs/<int:log_id>", methods=["PUT"])
@require_auth
def update_log(user_id, log_id):
    log = VirtueLog.query.filter(VirtueLog.id == log_id, VirtueLog.user_id == user_id).first()
    if not log:
        return fail(404, "资源不存在", None)

    data = request.get_json() or {}
    if "virtue_type" in data:
        v = (data.get("virtue_type") or "").strip()
        if v in VIRTUE_TYPES:
            log.virtue_type = v
    if "completed" in data:
        log.completed = bool(data.get("completed"))
    if "reflection" in data:
        r = (data.get("reflection") or "").strip()
        if not valid_content(r):
            return fail(400, "感想超过2000字", None)
        log.reflection = r

    db.session.commit()
    logging.info("virtue update user_id=%s id=%s", user_id, log_id)
    return ok("success", None)


@virtue_bp.route("/logs/<int:log_id>", methods=["DELETE"])
@require_auth
def delete_log(user_id, log_id):
    log = VirtueLog.query.filter(VirtueLog.id == log_id, VirtueLog.user_id == user_id).first()
    if not log:
        return fail(404, "资源不存在", None)
    db.session.delete(log)
    db.session.commit()
    logging.info("virtue delete user_id=%s id=%s", user_id, log_id)
    return ok("success", None)
