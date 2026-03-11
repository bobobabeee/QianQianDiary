# -*- coding: utf-8 -*-
"""
测试用模型：仅用于 CRUD 测试，验证数据库连接是否正常
"""
from extensions import db


class TestRecord(db.Model):
    """测试表：用于验证增删改查"""
    __tablename__ = "test_records"

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    name = db.Column(db.String(64), nullable=False)
    email = db.Column(db.String(128), nullable=True)
    created_at = db.Column(db.DateTime, server_default=db.func.now())

    def to_dict(self):
        return {
            "id": self.id,
            "name": self.name,
            "email": self.email,
        }
