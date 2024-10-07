# manage.py inside /workspace/base/micro/service1/server
import os
import sys

# Add the root folder to the Python path to make the 'server.backend' module accessible
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

if __name__ == "__main__":
    os.environ.setdefault("DJANGO_SETTINGS_MODULE", "backend.settings")
    try:
        from django.core.management import execute_from_command_line
    except ImportError as exc:
        raise ImportError(
            "Couldn't import Django. Are you sure it's installed and "
            "available on your PYTHONPATH environment variable? Did you "
            "forget to activate a virtual environment?"
        ) from exc
    execute_from_command_line(sys.argv)
