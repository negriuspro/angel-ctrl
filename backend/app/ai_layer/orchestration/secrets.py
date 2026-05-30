from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class EncryptedSecretRef:
    name: str
    ciphertext_ref: str


def ensure_backend_only_secret_access() -> None:
    return None

