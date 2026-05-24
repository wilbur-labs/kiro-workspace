# Technical Environment: dogfood-todo-api

> Dogfood is a verification harness — the stack is picked for "runs anywhere with Python", NOT for production fidelity. If your real projects use FastAPI + Postgres + AWS, that's fine; you don't need dogfood to mirror them. The point is to exercise the M1 gates over three real units in a stack you can stand up in one command.

## Language and Package Manager

- **Python 3.12+**
- **uv** for all package management (no pip, poetry, or conda)
- `pyproject.toml` at `tasks/dogfood-todo-api/src/pyproject.toml`
- `uv.lock` committed locally to the dogfood src dir (not the repo — see `.gitignore`)

## Frameworks and Libraries

- **FastAPI** + **Pydantic v2** for the three unit services
- **httpx** for cross-unit calls inside smoke tests
- **PyJWT** for the auth unit's token issuing / verifying
- **uvicorn** to serve each unit on its own port locally

## Cloud and Deployment

- **None.** Dogfood runs locally only. `docker-compose.yml` may be used to start all three units; `make up` / `make down` or a small `run.sh` is equally fine — agent decides.
- No managed services, no IaC, no CI deployment.

## Testing

- **pytest** with **pytest-asyncio** (FastAPI is async)
- **httpx.AsyncClient** for both unit tests and cross-unit smoke
- Coverage minimum: **80%** for each unit's own code (lower than typical because dogfood code is throwaway)
- **mypy** strict mode on a per-unit basis
- **ruff** for linting + formatting
- Test layout:
  - `tasks/dogfood-todo-api/src/<unit>/tests/` — per-unit unit tests
  - `tasks/dogfood-todo-api/src/tests/smoke/` — cross-unit smoke tests required by M1.3 #2

## Code Quality Tooling

> Layer B of `.kiro/steering/code-quality.md` — the objective gate Build & Test
> enforces. Declared explicitly so the complexity/duplication thresholds don't
> stay on paper (this section was the gap dogfood surfaced — pytest/mypy/ruff
> alone don't gate cognitive complexity or duplication).

| Tool | Gate |
| --- | --- |
| `ruff check` | 0 new lint errors |
| `radon` + `xenon` | `xenon --max-absolute B` — any function over cognitive grade B fails (≈ cognitive ≤ 15) |
| `jscpd` | new-code duplication ≤ 3% |

Build & Test must actually execute these, not just list them:

```bash
ruff check .
xenon dogfood_todo_api --max-absolute B --max-modules A --max-average A
npx jscpd --pattern "**/*.py" --threshold 3 dogfood_todo_api
```

## Do NOT Use

> Each row prevents a class of bad code-gen that would defeat the dogfood verification.

| Prohibited | Reason | Use Instead |
| --- | --- | --- |
| `flask`, `django`, `starlette` directly | Tech-env pins FastAPI; switching frameworks invalidates examples | FastAPI |
| `pip`, `poetry`, `pipenv`, `pdm` | Project uses uv exclusively | uv |
| `requests` (sync HTTP) | Blocks asyncio loop, can't be used in smoke against async services | httpx |
| `unittest.mock` for upstream units in smoke | Defeats M1.3 #2 Part 1 (smoke must hit real generated code) | spin up real units via docker-compose / uvicorn subprocess |
| `eval`, `exec`, `compile`, `pickle.loads` on input | Even dogfood doesn't ship eval-on-input patterns | explicit deserialization (Pydantic) |
| SQLAlchemy, full ORMs | Overkill for the dogfood scope; AI may generate too much surface | `sqlite3` stdlib or one-file `aiosqlite` |
| External email / SMS providers (SES, Twilio, SendGrid) | Notification unit is stubbed by design (vision §Out-of-Scope) | print to stdout or write to `notifications.log` |

## Security Basics

> Dogfood-level. Documented here so AI-DLC's NFR phase has something to read, not because dogfood needs hardening.

- JWT signed with HS256, secret loaded from `JWT_SECRET` env var (default `"dogfood-insecure-secret"` if unset — a comment must flag this as dogfood-only).
- Bcrypt for the hardcoded test user's password hash (yes, even for one user — exercising the dependency surface is the point).
- TLS not enforced — dogfood runs on localhost only.
- No PII logging — todos may contain user-entered text, do not echo to stdout outside of the explicit notification-unit stub.

## Example Code Pattern

> Optional, but very effective at constraining AI-DLC's code-gen style. Keep these short.

A FastAPI endpoint should look like:

```python
from fastapi import APIRouter, Depends
from pydantic import BaseModel

from dogfood_todo_api.todo_crud.deps import get_current_user
from dogfood_todo_api.todo_crud.models import Todo

router = APIRouter(prefix="/todos", tags=["todos"])


class CreateTodoRequest(BaseModel):
    title: str
    description: str | None = None
    due_at: str | None = None


@router.post("", response_model=Todo, status_code=201)
async def create_todo(
    request: CreateTodoRequest,
    user_id: str = Depends(get_current_user),
) -> Todo:
    return await Todo.create(owner_user_id=user_id, **request.model_dump())
```

A smoke test should look like:

```python
import pytest
from httpx import AsyncClient


@pytest.mark.asyncio
async def test_todo_crud_accepts_token_from_real_auth_unit(
    auth_client: AsyncClient,
    todo_client: AsyncClient,
) -> None:
    # happy path — hit the real auth service for a token, then use it
    login = await auth_client.post("/login", json={"username": "alice", "password": "wonderland"})
    token = login.json()["access_token"]

    create = await todo_client.post(
        "/todos",
        headers={"Authorization": f"Bearer {token}"},
        json={"title": "buy milk"},
    )
    assert create.status_code == 201
    assert create.json()["title"] == "buy milk"


@pytest.mark.asyncio
async def test_todo_crud_rejects_token_from_wrong_signing_key(
    todo_client: AsyncClient,
) -> None:
    # error path — token forged with a different key must be rejected
    bad_token = "ey...forged..."
    create = await todo_client.post(
        "/todos",
        headers={"Authorization": f"Bearer {bad_token}"},
        json={"title": "x"},
    )
    assert create.status_code == 401
```
