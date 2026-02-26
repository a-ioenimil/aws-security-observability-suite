from fastapi import FastAPI, HTTPException
from prometheus_client import make_asgi_app
from opentelemetry import metrics
from opentelemetry.exporter.prometheus import PrometheusMetricReader
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor

from src.presentation.restAPI.routers.whoami_router import whoami_router

app = FastAPI()

# Set up the Prometheus Metric Reader
reader = PrometheusMetricReader()
provider = MeterProvider(metric_readers=[reader])
metrics.set_meter_provider(provider)

# Mount the Prometheus ASGI app for the /metrics endpoint
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)

app.include_router(whoami_router)

@app.get("/")
async def root():
    return {"message": "Hello World"}

@app.get("/error")
async def simulate_error():
    raise HTTPException(status_code=500, detail="This is a simulated internal server error.")

# Instrument the FastAPI app for OpenTelemetry AFTER all routes are defined
FastAPIInstrumentor.instrument_app(app)