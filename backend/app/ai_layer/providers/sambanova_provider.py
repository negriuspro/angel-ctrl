from app.ai_layer.providers.remote_provider import RemoteProvider


class SambaNovaProvider(RemoteProvider):
    provider_id = "sambanova"
    provider_type = "hosted"
    base_url = "https://api.sambanova.ai"
