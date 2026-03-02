from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    PROJECT_NAME: str = "Executive OS"
    DATABASE_URL: str = "postgresql+asyncpg://postgres:postgres@localhost/executive_os"
    
    # App Settings
    SECRET_KEY: str = "secret-super-long-key-for-auth"
    OPENAI_API_KEY: str = "your-openai-api-key"
    
    class Config:
        env_file = ".env"

settings = Settings()
