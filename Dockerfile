# Python base image — "slim" varyant küçük boyut sağlar (~150MB vs ~900MB)
FROM python:3.11-slim

# Güvenlik: root yerine ayrı bir kullanıcıyla çalıştır
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Çalışma dizinini ayarla
WORKDIR /app

# Önce sadece requirements.txt kopyala ve bağımlılıkları yükle
# Bu Docker cache sayesinde her build'de tekrar yüklenmesini engeller
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Uygulama dosyalarını kopyala
COPY . .

# Kullanıcıyı değiştir (güvenlik best practice)
USER appuser

# Uygulamanın dinleyeceği port
EXPOSE 5000

# Production'da gunicorn ile çalıştır
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--timeout", "120", "run:app"]
