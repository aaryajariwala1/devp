from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    DATABASE_URL: str = "postgresql+asyncpg://takatrack:takatrack_secret@localhost:5432/takatrack_db"
    SYNC_DATABASE_URL: str = "postgresql+psycopg2://takatrack:takatrack_secret@localhost:5432/takatrack_db"
    SECRET_KEY: str = "change-me-to-a-random-secret-key-in-production"
    CONFIDENCE_THRESHOLD: float = 0.75
    LOW_STOCK_THRESHOLD: int = 5
    MODEL_CACHE_DIR: str = "./model_cache"
    DEBUG: bool = True

    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")


settings = Settings()
