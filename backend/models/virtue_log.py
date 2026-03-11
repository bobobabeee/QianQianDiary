# -*- coding: utf-8 -*-
"""
美德践行记录模型
"""
from extensions import db

VIRTUE_TYPES = ("友好亲和", "勇于担当", "善待他人", "帮助给予", "感恩之心", "勤学不辍", "值得信赖")


class VirtueLog(db.Model):
    __tablename__ = "virtue_logs"

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False, index=True)
    virtue_type = db.Column(db.String(32), nullable=False)
    completed = db.Column(db.Boolean, nullable=False, default=True)
    reflection = db.Column(db.String(2000), nullable=True, default="")
    date = db.Column(db.String(10), nullable=False, index=True)  # yyyy-MM-dd
    created_at = db.Column(db.DateTime, server_default=db.func.now())
    updated_at = db.Column(db.DateTime, server_default=db.func.now(), onupdate=db.func.now())

    def to_dict(self):
        return {
            "id": self.id,
            "virtue_type": self.virtue_type,
            "completed": self.completed,
            "reflection": self.reflection or "",
            "date": self.date,
            "created_at": self.created_at.strftime("%Y-%m-%d %H:%M:%S") if self.created_at else None,
        }
