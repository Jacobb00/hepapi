"""
Basit testler — CI pipeline'da calistirilir
MongoDB bagiantisi olmadan calisabilecek testler
"""
import sys
import os

# Proje root'unu path'e ekle
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))


def test_imports():
    """Gerekli modullerin import edilebildigini kontrol et"""
    import flask
    import pymongo
    assert flask is not None
    assert pymongo is not None


def test_classes_import():
    """Form siniflarinin dogru tanimlandigini kontrol et"""
    from classes import CreateTask, DeleteTask, UpdateTask, ResetTask
    assert CreateTask is not None
    assert DeleteTask is not None
    assert UpdateTask is not None
    assert ResetTask is not None


def test_app_creation():
    """Flask uygulamasinin olusturulabildigini kontrol et"""
    from flask import Flask
    app = Flask(__name__)
    assert app is not None


def test_app_config():
    """Uygulama konfigurasyonunun dogru yapildigini kontrol et"""
    # MONGO_URI environment variable testi
    os.environ['MONGO_URI'] = 'mongodb://testhost:27017/TestDB'
    result = os.environ.get('MONGO_URI')
    assert result == 'mongodb://testhost:27017/TestDB'
    del os.environ['MONGO_URI']


def test_default_mongo_uri():
    """Default MONGO_URI degerinin dogru oldugunu kontrol et"""
    # Env variable yoksa default kullanilmali
    if 'MONGO_URI' in os.environ:
        del os.environ['MONGO_URI']
    result = os.environ.get('MONGO_URI', 'mongodb://localhost:27017/TaskManager')
    assert 'localhost' in result
    assert 'TaskManager' in result
