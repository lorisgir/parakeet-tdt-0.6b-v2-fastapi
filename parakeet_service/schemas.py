from typing import Any

from pydantic import BaseModel, Field


class TranscriptionResponse(BaseModel):
    text: str = Field(..., description="Plain transcription.")
    timestamps: dict[str, Any] | None = Field(
        None,
        description="Word/segment/char offsets (see NeMo docs).",
    )