"""Админ API."""
from fastapi import APIRouter
from app.api.v1.admin import auth

router = APIRouter()
router.include_router(auth.router)

