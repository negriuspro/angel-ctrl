from pydantic import BaseModel


class ApiStatus(BaseModel):
    status: str
    detail: str | None = None

