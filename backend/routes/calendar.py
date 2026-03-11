# -*- coding: utf-8 -*-
"""
日历视图：按日期返回是否有日记、美德是否完成
"""
from flask import Blueprint, request

from models.diary import Diary
from models.virtue_log import VirtueLog
from utils.response import ok, fail
from utils.validators import valid_date
from middleware.auth import require_auth

calendar_bp = Blueprint("calendar", __name__, url_prefix="/api/v1/calendar")


@calendar_bp.route("", methods=["GET"])
@require_auth
def get_calendar(user_id):
    """GET /api/v1/calendar?start_date=2026-03-01&end_date=2026-03-31"""
    start_date = request.args.get("start_date", "").strip()
    end_date = request.args.get("end_date", "").strip()

    if not valid_date(start_date):
        return fail(400, "start_date 格式为 yyyy-MM-dd", None)
    if not valid_date(end_date):
        return fail(400, "end_date 格式为 yyyy-MM-dd", None)
    if start_date > end_date:
        return fail(400, "start_date 不能大于 end_date", None)

    diary_dates = set(
        r.date for r in Diary.query.filter(
            Diary.user_id == user_id,
            Diary.date >= start_date,
            Diary.date <= end_date,
        ).with_entities(Diary.date).distinct()
    )

    virtue_dates = set(
        r.date for r in VirtueLog.query.filter(
            VirtueLog.user_id == user_id,
            VirtueLog.date >= start_date,
            VirtueLog.date <= end_date,
            VirtueLog.completed == True,
        ).with_entities(VirtueLog.date).distinct()
    )

    from datetime import datetime, timedelta
    dates = {}
    dt = datetime.strptime(start_date, "%Y-%m-%d")
    end_dt = datetime.strptime(end_date, "%Y-%m-%d")
    while dt <= end_dt:
        d = dt.strftime("%Y-%m-%d")
        dates[d] = {"has_diary": d in diary_dates, "virtue_completed": d in virtue_dates}
        dt += timedelta(days=1)

    return ok("success", {"dates": dates})
