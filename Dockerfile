FROM python:3.9-slim
WORKDIR /app

# Telepítjük a függőségeket
RUN pip install --no-cache-dir flask mysql-connector-python

# A lényeg: az app mappából másolunk át mindent a konténer /app mappájába
COPY ./app .

EXPOSE 5000
CMD ["python", "app.py"]