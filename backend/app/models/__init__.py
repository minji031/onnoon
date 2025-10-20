# app/models/__init__.py

from ..database import Base
from .users import User, EyeFatigueRecord

__all__ = ["Base", "User", "EyeFatigueRecord"]