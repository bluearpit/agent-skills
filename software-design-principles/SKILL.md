---
name: software-design-principles
description: >-
  Applies DRY, single source of truth, and separation of concerns when changing
  product packaging, pricing, plans, feature limits, copy, or duplicated
  constants. Use when adding or editing plan names, prices, CTAs, quotas,
  feature flags, config defaults, shared labels across bot/web/API, or when
  the user mentions DRY, packaging, single source of truth, or duplicated
  strings/magic numbers.
---

# Software design principles

General engineering defaults for product and config changes across any project.

## When this skill applies

Use automatically when the change touches:

- Plan / tier names, prices, billing CTAs, packaging copy
- Feature limits (quotas, caps, free vs paid entitlements)
- Values that appear in more than one surface (bot, web, API, emails, admin)
- New config keys, env vars, or “tunables” vs secrets vs marketing copy
- Refactors that extract shared constants or modules

## Core principles

### 1. DRY (Don't Repeat Yourself)

If the same fact must stay consistent in two places, define it once and import/reuse it.

- Prefer one module, constant map, or config schema over copy-paste.
- Duplication of *behavior* (two code paths that must stay identical) is worse than duplication of *incidental* text that intentionally diverges.
- Before adding a string or number: search the repo for the same literal. If it already exists for the same meaning, reuse the shared definition.

### 2. Single source of truth

Each concept has exactly one authoritative definition.

| Concept | Typical home | Not here |
|---------|--------------|----------|
| Product packaging (plan labels, display prices, CTAs, entitlements) | App/domain module (e.g. `product.py`, `pricing.ts`, `plans` package) | Scattered bot handlers, templates, payment providers |
| Secrets (API keys, tokens, DB URLs) | Secret manager / env | Code, docs committed to git, DB config table |
| Tunables (intervals, TTLs, thresholds) | Config store or env with defaults | Hardcoded only in one call site with no override |
| Provider IDs (Stripe price IDs) | Env / secrets | Product display labels (those stay in product module) |
| Schema constraints (allowed plan enums) | Migrations / DB CHECK + mirrored app constants | Only one of DB or app without the other when both enforce |

When product copy changes (“Pro — $5/mo”), update the product module once; bot, web, and emails should consume helpers—not restate the string.

### 3. Separation of concerns

Keep layers responsible for one job:

- **Product / packaging** — What the customer buys and how it is described (plans, limits, CTAs).
- **Payments / providers** — How money moves (Stripe session creation, webhooks). Map provider IDs → plan keys; do not own marketing strings.
- **Auth / entitlements** — Who may do what (`is_paid_plan`, gate checks). Depend on plan keys from the product module.
- **Presentation** — Templates and bot messages format and send; they do not invent prices or plan names.
- **Ops config** — Runtime knobs and feature flags; not permanent brand packaging unless the product explicitly makes a limit configurable.

### 4. Name the abstraction after the domain

Prefer `product`, `plans`, `entitlements`, `pricing` over vague `constants` or `utils` dumps. Callers should read `plan_cta("pro")` and know where truth lives.

### 5. Change checklist

Before finishing a packaging or shared-constant change:

1. Is there already a single module for this fact? Extend it; do not add a second literal.
2. Will bot, web, API, and admin stay in sync automatically after this change?
3. Are secrets still out of product code, and provider IDs still out of user-facing copy?
4. Did tests cover the shared helpers (plan membership, CTA text, limits), not only one UI path?
5. Update project docs only where architecture/patterns changed—not every string tweak.

## Anti-patterns

- Hardcoding `"Subscribe to Pro — $5/mo"` (or any price/plan label) in a handler or template.
- Checking `plan == "pro"` in one place and `plan in ("pro", "premium")` in another without a shared helper.
- Putting display prices next to Stripe price IDs in the same env blob without a clear product layer.
- “Just this once” duplicate because the other call site is in another package—still extract shared truth.
- A god `config` object that mixes secrets, tunables, and marketing copy with no boundaries.

## Good pattern (illustrative)

```text
product / plans module
  ├── PLAN_LABELS, DISPLAY_PRICES, CTAs, LIMITS
  ├── is_paid_plan(plan) / plan_cta(plan)
  └── used by: bot, web templates, admin, entitlement checks

payments layer
  └── maps STRIPE_PRICE_ID_* → plan key; no "$5/mo" strings

config / secrets
  └── tokens, price IDs, feature flags — not plan marketing copy
```

## Project-specific notes

If the repo already documents a packaging module path (e.g. in `CLAUDE.md` / `AGENTS.md`), follow that path. This skill states the *principle*; the repo names the *file*.
