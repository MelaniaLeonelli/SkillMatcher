from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base


# =========================================================
# DATABASE URL
# Indica a SQLAlchemy quale database utilizzare.
# In questo caso utilizziamo SQLite.
# =========================================================

DATABASE_URL = "sqlite:///./skillmatcher.db"


# =========================================================
# ENGINE
# L'engine gestisce la connessione tra SQLAlchemy
# e il database SQLite.
# =========================================================

engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False}
)


# =========================================================
# SESSION
# SessionLocal permette di creare sessioni attraverso
# le quali il backend può leggere e modificare il database.
# =========================================================

SessionLocal = sessionmaker(
    autocommit=False,
    autoflush=False,
    bind=engine
)


# =========================================================
# BASE
# Tutti i modelli definiti in models.py erediteranno
# da questa classe Base.
# =========================================================

Base = declarative_base()


# =========================================================
# GET DATABASE
# Crea una sessione del database per una richiesta
# e la chiude automaticamente al termine.
# =========================================================

def get_db():
    db = SessionLocal()

    try:
        yield db
    finally:
        db.close()