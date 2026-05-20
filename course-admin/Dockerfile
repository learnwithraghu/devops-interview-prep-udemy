FROM python:3.12-slim

WORKDIR /app

COPY app/ ./

EXPOSE 8080

ENV PYTHONUNBUFFERED=1

CMD ["python", "main.py"]
