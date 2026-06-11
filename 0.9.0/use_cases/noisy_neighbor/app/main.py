"""
noisy-app — multi-tenant HTTP service for the MDAI noisy-neighbor lab.

Endpoints
---------
- GET  /work?cost=N                runs N small Postgres queries, holding a connection.
                                   Reads X-Tenant-ID header. Per-tenant asyncpg pool.
                                   Injects 10% 503 (simulating timeouts/conn failures
                                   under DB pressure, mostly visible from the noisy tenant
                                   because it has the most requests).
- GET  /metrics                    Prometheus scrape endpoint.
- GET  /healthz                    Liveness.
- POST /admin/rate-limits          {"tenant":"...","rps":N}  apply or lift throttle.
- DELETE /admin/rate-limits/{t}    Lift throttle for one tenant.

Tracing
-------
Every request creates a span via the OTel FastAPI instrumentation. The /work handler
adds a `tenant` attribute (matched by the tail sampler) and sets Status.ERROR for
either an injected 503 or a 429 throttle (with attribute throttled=true).

Span pipeline: app SDK → trace-balancer → gateway (tail_sampling).
"""

from __future__ import annotations

import asyncio
import os
import random
import time
from contextlib import asynccontextmanager

import asyncpg
from fastapi import FastAPI, HTTPException, Request, Response
from fastapi.responses import PlainTextResponse
from opentelemetry import trace
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.instrumentation.asyncpg import AsyncPGInstrumentor
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.trace import Status, StatusCode
from prometheus_client import (
    CONTENT_TYPE_LATEST,
    CollectorRegistry,
    Counter,
    Gauge,
    generate_latest,
)
from pydantic import BaseModel

PG_DSN = os.environ.get(
    "PG_DSN", "postgres://app:app@postgres.noisy-neighbor.svc.cluster.local:5432/app"
)
POOL_MAX = int(os.environ.get("POOL_MAX_PER_TENANT", "30"))
POOL_MIN = int(os.environ.get("POOL_MIN_PER_TENANT", "1"))
ERROR_INJECT_PROB = float(os.environ.get("ERROR_INJECT_PROB", "0.10"))
OTLP_ENDPOINT = os.environ.get(
    "OTEL_EXPORTER_OTLP_ENDPOINT", "http://trace-balancer-collector.mdai:4317"
)
SERVICE_NAME = os.environ.get("OTEL_SERVICE_NAME", "noisy-app")

resource = Resource.create({"service.name": SERVICE_NAME})
provider = TracerProvider(resource=resource)
provider.add_span_processor(
    BatchSpanProcessor(OTLPSpanExporter(endpoint=OTLP_ENDPOINT, insecure=True))
)
trace.set_tracer_provider(provider)
tracer = trace.get_tracer("noisy-app")
AsyncPGInstrumentor().instrument()

registry = CollectorRegistry()
db_conns = Gauge(
    "db_connections_per_tenant",
    "Active Postgres connections held by each tenant pool",
    ["tenant"],
    registry=registry,
)
req_total = Counter(
    "app_requests_total",
    "Total app requests",
    ["tenant", "status"],
    registry=registry,
)
throttled_total = Counter(
    "app_throttled_total",
    "Requests rejected by the rate-limiter middleware",
    ["tenant"],
    registry=registry,
)
errors_total = Counter(
    "app_errors_total",
    "Requests that returned 5xx (including injected failures)",
    ["tenant"],
    registry=registry,
)

pools: dict[str, asyncpg.Pool] = {}
pools_lock = asyncio.Lock()
rate_limits: dict[str, float] = {}
buckets: dict[str, tuple[float, float]] = {}


async def get_pool(tenant: str) -> asyncpg.Pool:
    pool = pools.get(tenant)
    if pool is not None:
        return pool
    async with pools_lock:
        pool = pools.get(tenant)
        if pool is not None:
            return pool
        pool = await asyncpg.create_pool(
            dsn=PG_DSN,
            min_size=POOL_MIN,
            max_size=POOL_MAX,
            command_timeout=30,
            server_settings={"application_name": f"noisy-app:{tenant}"},
        )
        pools[tenant] = pool
        return pool


async def gauge_refresher():
    while True:
        for tenant, pool in list(pools.items()):
            db_conns.labels(tenant=tenant).set(pool.get_size() - pool.get_idle_size())
        await asyncio.sleep(1.0)


def consume_token(tenant: str) -> bool:
    rps = rate_limits.get(tenant)
    if rps is None or rps <= 0:
        return True
    now = time.monotonic()
    tokens, last = buckets.get(tenant, (rps, now))
    tokens = min(rps, tokens + (now - last) * rps)
    if tokens >= 1.0:
        buckets[tenant] = (tokens - 1.0, now)
        return True
    buckets[tenant] = (tokens, now)
    return False


@asynccontextmanager
async def lifespan(_: FastAPI):
    task = asyncio.create_task(gauge_refresher())
    try:
        yield
    finally:
        task.cancel()
        for pool in pools.values():
            await pool.close()


app = FastAPI(lifespan=lifespan)
FastAPIInstrumentor.instrument_app(app, excluded_urls="/metrics,/healthz")


@app.middleware("http")
async def rate_limit_mw(request: Request, call_next):
    path = request.url.path
    if path.startswith("/admin") or path in ("/metrics", "/healthz"):
        return await call_next(request)

    tenant = request.headers.get("x-tenant-id", "unknown")
    span = trace.get_current_span()
    span.set_attribute("tenant", tenant)

    if not consume_token(tenant):
        throttled_total.labels(tenant=tenant).inc()
        req_total.labels(tenant=tenant, status="429").inc()
        span.set_attribute("throttled", True)
        span.set_attribute("http.response.status_code", 429)
        span.set_status(Status(StatusCode.ERROR, "rate limited"))
        return PlainTextResponse("rate limited", status_code=429)

    response = await call_next(request)
    req_total.labels(tenant=tenant, status=str(response.status_code)).inc()
    return response


@app.get("/healthz")
async def healthz():
    return {"ok": True}


@app.get("/metrics")
async def metrics():
    return Response(generate_latest(registry), media_type=CONTENT_TYPE_LATEST)


@app.get("/work")
async def work(request: Request, cost: int = 3):
    tenant = request.headers.get("x-tenant-id", "unknown")
    cost = max(1, min(cost, 20))

    span = trace.get_current_span()
    span.set_attribute("tenant", tenant)
    span.set_attribute("work.cost", cost)

    # Inject ~ERROR_INJECT_PROB 5xx — simulates timeouts / conn failures under DB pressure.
    # Statistically these mostly hit the noisy tenant simply because it has more requests.
    if random.random() < ERROR_INJECT_PROB:
        errors_total.labels(tenant=tenant).inc()
        span.set_attribute("error.injected", True)
        span.set_status(Status(StatusCode.ERROR, "simulated db timeout"))
        raise HTTPException(status_code=503, detail="simulated db timeout")

    pool = await get_pool(tenant)
    try:
        async with pool.acquire() as conn:
            async with conn.transaction():
                for _ in range(cost):
                    await conn.fetchval("SELECT pg_sleep(0.05)")
        return {"tenant": tenant, "cost": cost, "ok": True}
    except Exception as e:
        errors_total.labels(tenant=tenant).inc()
        span.set_status(Status(StatusCode.ERROR, str(e)[:120]))
        raise HTTPException(status_code=503, detail=str(e))


class RateLimit(BaseModel):
    tenant: str
    rps: float


@app.post("/admin/rate-limits", status_code=204)
async def set_rate_limit(body: RateLimit):
    if body.rps <= 0:
        rate_limits.pop(body.tenant, None)
        buckets.pop(body.tenant, None)
    else:
        rate_limits[body.tenant] = body.rps
    return Response(status_code=204)


@app.delete("/admin/rate-limits/{tenant}", status_code=204)
async def clear_rate_limit(tenant: str):
    rate_limits.pop(tenant, None)
    buckets.pop(tenant, None)
    return Response(status_code=204)


@app.get("/admin/rate-limits")
async def list_rate_limits():
    return rate_limits
