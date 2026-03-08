import logging
from pythonjsonlogger import jsonlogger
from fastapi import FastAPI, HTTPException
from prometheus_client import make_asgi_app

from opentelemetry import trace, metrics
from opentelemetry.exporter.prometheus import PrometheusMetricReader
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.logging import LoggingInstrumentor

from src.presentation.restAPI.routers.whoami_router import whoami_router

# Configure structured JSON logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)
logHandler = logging.StreamHandler()
# Using custom format to capture OpenTelemetry added fields
formatter = jsonlogger.JsonFormatter(
    fmt="%(asctime)s %(levelname)s %(name)s %(filename)s %(funcName)s %(lineno)d %(message)s %(trace_id)s %(span_id)s"
)
logHandler.setFormatter(formatter)
logger.handlers.clear()
logger.addHandler(logHandler)

# Instrument logging to include trace_id and span_id
LoggingInstrumentor().instrument(set_logging_format=False)

resource = Resource.create({"service.name": "whoami-service"})

# Set up tracing
tracer_provider = TracerProvider(resource=resource)
otlp_exporter = OTLPSpanExporter() # Uses OTEL_EXPORTER_OTLP_ENDPOINT from env
span_processor = BatchSpanProcessor(otlp_exporter)
tracer_provider.add_span_processor(span_processor)
trace.set_tracer_provider(tracer_provider)

# Set up the Prometheus Metric Reader
reader = PrometheusMetricReader()
meter_provider = MeterProvider(resource=resource, metric_readers=[reader])
metrics.set_meter_provider(meter_provider)

app = FastAPI()

# Mount the Prometheus ASGI app for the /metrics endpoint
metrics_app = make_asgi_app()
app.mount("/metrics", metrics_app)

app.include_router(whoami_router)

@app.get("/")
async def root():
    logger.info("Handling root request")
    return {"message": "Hello World"}

@app.get("/error")
async def simulate_error():
    logger.error("Handling error request - simulating 500")
    raise HTTPException(status_code=500, detail="This is a simulated internal server error.")

# Instrument the FastAPI app for OpenTelemetry AFTER all routes are defined
FastAPIInstrumentor.instrument_app(app)