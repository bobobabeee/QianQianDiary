# -*- coding: utf-8 -*-
"""
愿景板模块：增删改查 + 图片上传到腾讯云 COS
"""
import logging
from flask import Blueprint, request

from extensions import db
from models.vision_item import VisionItem, VISION_CATEGORIES
from services.cos_service import upload_vision_image, allowed_file
from utils.response import ok, fail
from utils.validators import valid_content
from middleware.auth import require_auth

vision_bp = Blueprint("vision", __name__, url_prefix="/api/v1/vision")


@vision_bp.route("/items", methods=["GET"])
@require_auth
def list_items(user_id):
    category = request.args.get("category", "").strip()
    if category and category not in VISION_CATEGORIES:
        return fail(400, "无效的 category", None)
    q = VisionItem.query.filter(VisionItem.user_id == user_id)
    if category:
        q = q.filter(VisionItem.category == category)
    items = q.order_by(VisionItem.id.asc()).all()
    return ok("success", {"list": [i.to_dict() for i in items], "total": len(items)})


@vision_bp.route("/items", methods=["POST"])
@require_auth
def create_item(user_id):
    data = request.get_json() or {}
    category = (data.get("category") or "growth").strip()
    title = (data.get("title") or "").strip()[:128]
    description = (data.get("description") or "").strip()[:512]
    image_url = (data.get("image_url") or "").strip()[:512]
    target_date = (data.get("target_date") or "").strip()[:32]

    if category not in VISION_CATEGORIES:
        return fail(400, "无效的 category", None)

    item = VisionItem(user_id=user_id, category=category, title=title or "添加你的愿景",
                      description=description, image_url=image_url, target_date=target_date)
    db.session.add(item)
    db.session.commit()
    logging.info("vision create user_id=%s id=%s", user_id, item.id)
    return ok("success", {"id": item.id})


@vision_bp.route("/items/<int:item_id>", methods=["PUT"])
@require_auth
def update_item(user_id, item_id):
    item = VisionItem.query.filter(VisionItem.id == item_id, VisionItem.user_id == user_id).first()
    if not item:
        return fail(404, "资源不存在", None)
    data = request.get_json() or {}
    if "category" in data:
        c = (data.get("category") or "").strip()
        if c in VISION_CATEGORIES:
            item.category = c
    if "title" in data:
        item.title = (data.get("title") or "").strip()[:128] or item.title
    if "description" in data:
        item.description = (data.get("description") or "").strip()[:512]
    if "image_url" in data:
        item.image_url = (data.get("image_url") or "").strip()[:512]
    if "target_date" in data:
        item.target_date = (data.get("target_date") or "").strip()[:32]
    db.session.commit()
    logging.info("vision update user_id=%s id=%s", user_id, item_id)
    return ok("success", None)


@vision_bp.route("/items/<int:item_id>", methods=["DELETE"])
@require_auth
def delete_item(user_id, item_id):
    item = VisionItem.query.filter(VisionItem.id == item_id, VisionItem.user_id == user_id).first()
    if not item:
        return fail(404, "资源不存在", None)
    db.session.delete(item)
    db.session.commit()
    logging.info("vision delete user_id=%s id=%s", user_id, item_id)
    return ok("success", None)


@vision_bp.route("/upload", methods=["POST"])
@require_auth
def upload_image(user_id):
    """上传图片到 COS，multipart/form-data 字段 file"""
    if "file" not in request.files:
        return fail(400, "请选择要上传的图片", None)
    f = request.files["file"]
    if not f or f.filename == "":
        return fail(400, "请选择要上传的图片", None)
    if not allowed_file(f.filename):
        return fail(400, "仅支持 jpg/png/gif/webp", None)

    url = upload_vision_image(f.stream, f.filename)
    if not url:
        return fail(500, "图片上传失败，请检查 COS 配置", None)
    logging.info("vision upload user_id=%s", user_id)
    return ok("success", {"url": url})
