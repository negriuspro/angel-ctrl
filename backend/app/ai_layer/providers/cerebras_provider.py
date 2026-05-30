from app.ai_layer.providers.remote_provider import RemoteProvider


class CerebrasProvider(RemoteProvider):
    provider_id = "cerebras"
    provider_type = "hosted"
    base_url = "https://api.cerebras.ai"
