# 1. Alap image: egy könnyű Python környezet
FROM python:3.9-slim

# 2. Munkakönyvtár beállítása a konténeren belül
WORKDIR /app

# 3. Szükséges függőségek másolása és telepítése
# (Ha van requirements.txt-d, ha nincs, telepítjük kézzel)
RUN pip install --no-cache-dir flask mysql-connector-python

# 4. Az alkalmazás kódjának átmásolása a konténerbe
COPY . .

# 5. A port, amin a Flask hallgat
EXPOSE 5000

# 6. Az alkalmazás indítása
CMD ["python", "app.py"]