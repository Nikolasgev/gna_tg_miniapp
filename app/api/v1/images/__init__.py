"""Images proxy and upload API."""
from fastapi import APIRouter, HTTPException, Query, UploadFile, File, status
from fastapi.responses import Response
import httpx
import os
import uuid
import logging
from pathlib import Path
from app.config import settings

logger = logging.getLogger(__name__)

router = APIRouter()

# Директория для хранения загруженных изображений
# Используем абсолютный путь относительно корня проекта (backend/)
# __file__ = backend/app/api/v1/images/__init__.py
# parent.parent.parent.parent.parent = backend/
BASE_DIR = Path(__file__).resolve().parent.parent.parent.parent.parent
UPLOAD_DIR = BASE_DIR / "uploads" / "images"
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)

# Логируем при инициализации модуля
import sys
logger.info(f"=== Images module initialized ===")
logger.info(f"__file__: {__file__}")
logger.info(f"BASE_DIR: {BASE_DIR}")
logger.info(f"UPLOAD_DIR: {UPLOAD_DIR}")
logger.info(f"UPLOAD_DIR exists: {UPLOAD_DIR.exists()}")
logger.info(f"UPLOAD_DIR absolute: {UPLOAD_DIR.absolute()}")
if UPLOAD_DIR.exists():
    try:
        files = list(UPLOAD_DIR.iterdir())
        logger.info(f"Files in UPLOAD_DIR: {[f.name for f in files]}")
    except Exception as e:
        logger.error(f"Error listing files: {e}")

# Разрешенные типы изображений
ALLOWED_IMAGE_TYPES = {"image/jpeg", "image/jpg", "image/png", "image/gif", "image/webp"}
MAX_FILE_SIZE = 10 * 1024 * 1024  # 10 MB


@router.get("/proxy")
async def proxy_image(
    url: str = Query(..., description="URL изображения для проксирования"),
):
    """
    Прокси для загрузки изображений с внешних источников.
    
    Решает проблему CORS при загрузке изображений в Flutter Web.
    """
    if not url or not url.startswith(("http://", "https://")):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Некорректный URL изображения",
        )

    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            response = await client.get(url, follow_redirects=True)
            
            if response.status_code != 200:
                raise HTTPException(
                    status_code=status.HTTP_502_BAD_GATEWAY,
                    detail=f"Не удалось загрузить изображение: {response.status_code}",
                )

            # Определяем content-type из заголовков или по расширению
            content_type = response.headers.get("content-type", "image/png")
            
            # Если content-type не указан, пытаемся определить по URL
            if not content_type.startswith("image/"):
                if url.endswith((".jpg", ".jpeg")):
                    content_type = "image/jpeg"
                elif url.endswith(".png"):
                    content_type = "image/png"
                elif url.endswith(".gif"):
                    content_type = "image/gif"
                elif url.endswith(".webp"):
                    content_type = "image/webp"
                else:
                    content_type = "image/png"  # По умолчанию

            return Response(
                content=response.content,
                media_type=content_type,
                headers={
                    "Cache-Control": "public, max-age=86400",  # Кэш на 1 день
                },
            )
    except httpx.TimeoutException:
        raise HTTPException(
            status_code=status.HTTP_504_GATEWAY_TIMEOUT,
            detail="Таймаут при загрузке изображения",
        )
    except httpx.RequestError as e:
        raise HTTPException(
            status_code=status.HTTP_502_BAD_GATEWAY,
            detail=f"Ошибка при загрузке изображения: {str(e)}",
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Внутренняя ошибка: {str(e)}",
        )


@router.post("/upload")
async def upload_image(
    file: UploadFile = File(...),
):
    """
    Загрузить изображение с устройства.
    
    Принимает файл изображения и сохраняет его на сервере.
    Возвращает URL для доступа к загруженному изображению.
    """
    logger.info(f"Upload request received: filename={file.filename}, content_type={file.content_type}")
    logger.info(f"UPLOAD_DIR: {UPLOAD_DIR}, exists: {UPLOAD_DIR.exists()}")
    
    # Проверяем тип файла
    if file.content_type not in ALLOWED_IMAGE_TYPES:
        logger.warning(f"Invalid file type: {file.content_type}")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Неподдерживаемый тип файла. Разрешенные типы: {', '.join(ALLOWED_IMAGE_TYPES)}",
        )
    
    # Читаем содержимое файла
    contents = await file.read()
    logger.info(f"File read: {len(contents)} bytes")
    
    # Проверяем размер файла
    if len(contents) > MAX_FILE_SIZE:
        logger.warning(f"File too large: {len(contents)} bytes")
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Файл слишком большой. Максимальный размер: {MAX_FILE_SIZE / 1024 / 1024} MB",
        )
    
    # Генерируем уникальное имя файла
    file_extension = Path(file.filename).suffix if file.filename else ".png"
    if not file_extension:
        # Определяем расширение по content-type
        if file.content_type == "image/jpeg" or file.content_type == "image/jpg":
            file_extension = ".jpg"
        elif file.content_type == "image/png":
            file_extension = ".png"
        elif file.content_type == "image/gif":
            file_extension = ".gif"
        elif file.content_type == "image/webp":
            file_extension = ".webp"
        else:
            file_extension = ".png"
    
    unique_filename = f"{uuid.uuid4()}{file_extension}"
    file_path = UPLOAD_DIR / unique_filename
    
    logger.info(f"Saving file to: {file_path}")
    logger.info(f"File path exists: {file_path.parent.exists()}")
    logger.info(f"File path parent writable: {os.access(file_path.parent, os.W_OK)}")
    
    # Сохраняем файл
    try:
        with open(file_path, "wb") as f:
            f.write(contents)
        logger.info(f"File saved successfully: {file_path}, size: {file_path.stat().st_size if file_path.exists() else 0} bytes")
    except Exception as e:
        logger.error(f"Error saving file: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Ошибка при сохранении файла: {str(e)}",
        )
    
    # Возвращаем URL для доступа к файлу
    # В production это должен быть полный URL с доменом
    image_url = f"/api/v1/images/uploads/{unique_filename}"
    
    logger.info(f"Upload successful: {image_url}")
    
    return {
        "url": image_url,
        "filename": unique_filename,
        "size": len(contents),
        "content_type": file.content_type,
    }


@router.get("/uploads/{filename}")
async def get_uploaded_image(filename: str):
    """
    Получить загруженное изображение по имени файла.
    """
    file_path = UPLOAD_DIR / filename
    
    logger.info(f"=== Image request ===")
    logger.info(f"Filename: {filename}")
    logger.info(f"UPLOAD_DIR: {UPLOAD_DIR}")
    logger.info(f"UPLOAD_DIR exists: {UPLOAD_DIR.exists()}")
    logger.info(f"File path: {file_path}")
    logger.info(f"File path absolute: {file_path.resolve()}")
    logger.info(f"File exists: {file_path.exists()}")
    
    if not file_path.exists():
        # Логируем список файлов в директории для отладки
        if UPLOAD_DIR.exists():
            try:
                files = list(UPLOAD_DIR.iterdir())
                logger.warning(f"File not found. Files in directory: {[f.name for f in files]}")
            except Exception as e:
                logger.error(f"Error listing files: {e}")
        else:
            logger.error(f"UPLOAD_DIR does not exist: {UPLOAD_DIR}")
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Изображение не найдено",
        )
    
    # Определяем content-type по расширению
    content_type = "image/png"
    if filename.endswith((".jpg", ".jpeg")):
        content_type = "image/jpeg"
    elif filename.endswith(".png"):
        content_type = "image/png"
    elif filename.endswith(".gif"):
        content_type = "image/gif"
    elif filename.endswith(".webp"):
        content_type = "image/webp"
    
    with open(file_path, "rb") as f:
        contents = f.read()
    
    return Response(
        content=contents,
        media_type=content_type,
        headers={
            "Cache-Control": "public, max-age=31536000",  # Кэш на 1 год
        },
    )

