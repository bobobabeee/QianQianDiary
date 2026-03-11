# -*- coding: utf-8 -*-
"""
成功日记模块：增删改查
"""
import logging
from flask import Blueprint, request

from extensions import db
from models.diary import Diary, DIARY_CATEGORIES
from utils.response import ok, fail
from utils.validators import valid_date, valid_content
from middleware.auth import require_auth

diary_bp = Blueprint("diary", __name__, url_prefix="/api/v1/diary")


@diary_bp.route("/entries", methods=["GET"])
@require_auth
def list_entries(user_id):
    page = max(1, int(request.args.get("page", 1)))
    page_size = min(50, max(1, int(request.args.get("page_size", 10))))
    date_filter = request.args.get("date", "").strip()  # 2026-03 或 2026-03-09
    category = request.args.get("category", "").strip()

    if category and category not in DIARY_CATEGORIES:
        return fail(400, "无效的 category", None)

    q = Diary.query.filter(Diary.user_id == user_id)
    if date_filter:
        if len(date_filter) == 10 and valid_date(date_filter):
            q = q.filter(Diary.date == date_filter)
        elif len(date_filter) == 7 and date_filter[4] == "-":  # 2026-03
            q = q.filter(Diary.date.like(f"{date_filter}%"))
    if category:
        q = q.filter(Diary.category == category)

    total = q.count()
    items = q.order_by(Diary.date.desc(), Diary.id.desc()).offset((page - 1) * page_size).limit(page_size).all()
    return ok("success", {"total": total, "list": [i.to_dict() for i in items]})


@diary_bp.route("/entries", methods=["POST"])
@require_auth
def create_entry(user_id):
    data = request.get_json() or {}
    content = (data.get("content") or "").strip()
    date_str = (data.get("date") or "").strip()
    category = (data.get("category") or "daily").strip()
    mood_icon = (data.get("mood_icon") or "").strip()[:64]

    if not content or len(content) < 5:
        return fail(400, "内容至少5个字符", None)
    if not valid_content(content):
        return fail(400, "内容超过2000字", None)
    if not valid_date(date_str):
        return fail(400, "日期格式为 yyyy-MM-dd", None)
    if category not in DIARY_CATEGORIES:
        return fail(400, "无效的 category", None)

    entry = Diary(user_id=user_id, content=content, date=date_str, category=category, mood_icon=mood_icon)
    db.session.add(entry)
    db.session.commit()
    logging.info("diary create user_id=%s id=%s", user_id, entry.id)
    return ok("success", {"diary_id": entry.id})


@diary_bp.route("/entries/<int:entry_id>", methods=["PUT"])
@require_auth
def update_entry(user_id, entry_id):
    entry = Diary.query.filter(Diary.id == entry_id, Diary.user_id == user_id).first()
    if not entry:
        return fail(404, "资源不存在", None)

    data = request.get_json() or {}
    if "content" in data:
        c = (data.get("content") or "").strip()
        if len(c) < 5:
            return fail(400, "内容至少5个字符", None)
        if not valid_content(c):
            return fail(400, "内容超过2000字", None)
        entry.content = c
    if "category" in data:
        cat = (data.get("category") or "").strip()
        if cat in DIARY_CATEGORIES:
            entry.category = cat
    if "mood_icon" in data:
        entry.mood_icon = (data.get("mood_icon") or "").strip()[:64]

    db.session.commit()
    logging.info("diary update user_id=%s id=%s", user_id, entry_id)
    return ok("success", None)


@diary_bp.route("/entries/<int:entry_id>", methods=["DELETE"])
@require_auth
def delete_entry(user_id, entry_id):
    entry = Diary.query.filter(Diary.id == entry_id, Diary.user_id == user_id).first()
    if not entry:
        return fail(404, "资源不存在", None)
    db.session.delete(entry)
    db.session.commit()
    logging.info("diary delete user_id=%s id=%s", user_id, entry_id)
    return ok("success", None)
