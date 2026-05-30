from app.ai_layer.providers.remote_provider import RemoteProvider


class OpenRouterProvider(RemoteProvider):
    provider_id = "openrouter"
    provider_type = "hosted"
    base_url = "https://openrouter.ai/api"
