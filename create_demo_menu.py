"""
Устаревшая копия в корне репозитория раньше сидировала кофе/десерты.
Актуальный сид для default-business — каталог волос/косметика: backend/create_demo_menu.py

Запуск из корня делегирует в backend (тот же DATABASE_URL).
"""
import os
import subprocess
import sys


def main() -> None:
    root = os.path.dirname(os.path.abspath(__file__))
    backend_dir = os.path.join(root, "backend")
    script = os.path.join(backend_dir, "create_demo_menu.py")
    if not os.path.isfile(script):
        print(
            "Ошибка: не найден backend/create_demo_menu.py.\n"
            "Сид выполняйте из каталога backend: python create_demo_menu.py"
        )
        sys.exit(1)
    rc = subprocess.call([sys.executable, script] + sys.argv[1:], cwd=backend_dir, env=os.environ.copy())
    sys.exit(rc)


if __name__ == "__main__":
    main()
