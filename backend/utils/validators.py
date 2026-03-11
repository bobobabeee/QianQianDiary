# -*- coding: utf-8 -*-
"""入参校验"""
import re

PHONE_PATTERN = re.compile(r"^1[3-9]\d{9}$")
DATE_PATTERN = re.compile(r"^\d{4}-\d{2}-\d{2}$")
MAX_CONTENT = 2000
MAX_TITLE = 128
MAX_DESC = 512


def valid_phone(phone: str) -> bool:
    return bool(phone and PHONE_PATTERN.match(phone.strip()))


def valid_date(s: str) -> bool:
    return bool(s and DATE_PATTERN.match(s.strip()))


def valid_content(s: str, max_len: int = MAX_CONTENT) -> bool:
    if s is None:
        return True
    return len(str(s).strip()) <= max_len
