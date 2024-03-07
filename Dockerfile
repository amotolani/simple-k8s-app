FROM python:3.13.0a4-alpine3.19

ARG UNAME=smile
ARG UID=2001
ARG GID=2001

RUN addgroup ${UNAME} -g ${GID} && adduser -G ${UNAME} -u ${UID} ${UNAME} -D

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

USER ${UID}:${GID}

CMD ["gunicorn","-b","0.0.0.0:8080","app:app"]