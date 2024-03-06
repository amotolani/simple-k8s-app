FROM python:3.9-alpine3.18

RUN addgroup smile && adduser -G smile -S smile

# set environment variables
ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1
ENV APP_HOME=/usr/app

WORKDIR $APP_HOME

COPY requirements.txt .

RUN pip install -r requirements.txt

COPY app.py app.py

RUN chown -R smile:smile $APP_HOME

RUN find / -xdev -perm /6000 -type f -exec chmod a-s {} \; || true

USER smile

CMD ["gunicorn","-b","0.0.0.0:8080","app:app"]