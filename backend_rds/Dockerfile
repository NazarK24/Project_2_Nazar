# Вибираємо офіційний базовий образ Python
FROM python:3.11-slim

# Встановлюємо робочу директорію всередині контейнера
WORKDIR /app

# Копіюємо файл requirements.txt і встановлюємо залежност
COPY requirements.txt /app/ 
RUN pip install --no-cache-dir -r requirements.txt

# Копіюємо весь код в контейне
COPY backend_rds /app/

# Відкриваємо порт, на якому буде працюва
EXPOSE 8001

# Запускаємо додаток
CMD ["python", "manage.py", "runserver", "0.0.0.0:8001"]