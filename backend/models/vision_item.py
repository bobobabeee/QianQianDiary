# -*- coding: utf-8 -*-
"""
愿景板模型
"""
from extensions import db

VISION_CATEGORIES = ("work", "health", "relationship", "growth", "daily")


class VisionItem(db.Model):
    __tablename__ = "vision_items"

    id = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_id = db.Column(db.Integer, db.ForeignKey("users.id"), nullable=False, index=True)
    category = db.Column(db.String(32), nullable=False, default="growth")
    title = db.Column(db.String(128), nullable=False, default="")
    description = db.Column(db.String(512), nullable=True, default="")
    image_url = db.Column(db.String(512), nullable=True, default="")
    target_date = db.Column(db.String(32), nullable=True, default="")
    created_at = db.Column(db.DateTime, server_default=db.func.now())
    updated_at = db.Column(db.DateTime, server_default=db.func.now(), onupdate=db.func.now())

    def to_dict(self):
        return {
            "id": self.id,
            "category": self.category,
            "title": self.title,
            "description": self.description or "",
            "image_url": self.image_url or "",
            "target_date": self.target_date or "",
            "created_at": self.created_at.strftime("%Y-%m-%d %H:%M:%S") if self.created_at else None,
        }
