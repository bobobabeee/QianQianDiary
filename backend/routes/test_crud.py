# -*- coding: utf-8 -*-
"""
CRUD 测试接口：用于验证数据库连接和增删改查是否正常
"""
from flask import Blueprint, request, jsonify

from extensions import db
from models.test_record import TestRecord

test_bp = Blueprint("test", __name__)


@test_bp.route("/crud", methods=["GET"])
def list_records():
    """读取：列出所有测试记录"""
    records = TestRecord.query.order_by(TestRecord.id.desc()).all()
    return jsonify([r.to_dict() for r in records])


@test_bp.route("/crud", methods=["POST"])
def create_record():
    """创建：新增一条测试记录"""
    data = request.get_json() or {}
    name = (data.get("name") or "").strip() or "未命名"
    email = (data.get("email") or "").strip() or None

    record = TestRecord(name=name, email=email)
    db.session.add(record)
    db.session.commit()

    return jsonify(record.to_dict()), 201


@test_bp.route("/crud/<int:record_id>", methods=["PUT"])
def update_record(record_id):
    """更新：修改指定记录"""
    record = TestRecord.query.get(record_id)
    if not record:
        return jsonify({"message": "记录不存在"}), 404

    data = request.get_json() or {}
    if "name" in data:
        record.name = (data.get("name") or "").strip() or record.name
    if "email" in data:
        record.email = (data.get("email") or "").strip() or None

    db.session.commit()
    return jsonify(record.to_dict())


@test_bp.route("/crud/<int:record_id>", methods=["DELETE"])
def delete_record(record_id):
    """删除：删除指定记录"""
    record = TestRecord.query.get(record_id)
    if not record:
        return jsonify({"message": "记录不存在"}), 404

    db.session.delete(record)
    db.session.commit()
    return jsonify({"message": "已删除"})
