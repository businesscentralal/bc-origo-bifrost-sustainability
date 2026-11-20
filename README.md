# Bifröst Sustainability

**App name:** Bifrost Sustainability
**Publisher:** Origo — **Version:** 28.0.0.0 — **Target:** Cloud (BC 28.0, runtime 17.0)
**App ID:** `4610dc38-9c6c-43da-bd9f-b6954d74694a` — **Test app ID:** `09e9f1ab-c3c7-40c8-a4c0-674daa06f066`
**Object ID range:** 70009200–70009249 (tests 98000–98099) — **Namespace:** `Origo.Bifrost.Sustainability`

Bifrost Sustainability makes Microsoft's **Sustainability** app callable from outside Business Central through
Bifröst message types, so an agent can read emissions, maintain the chart of sustainability accounts, categories and
goals, and prepare sustainability journals. It is built on the same basis as
[Bifrost Subscription Billing](https://github.com/businesscentralal/bc-origo-bifrost-subscription-billing) and
[Bifrost Quality Management](https://github.com/businesscentralal/bc-origo-bifrost-quality-management).

**Microsoft source:** <https://github.com/microsoft/BCApps/tree/main/src/Apps/W1/Sustainability>

**Message types:** none yet. The first release adds the `Sustainability.*` reads, master-data writes and journal
types listed in the release tracking issue. Journal posting and ledger reversal come in release 2.

Foundation discovers this app on **Bifrost Setup** through its application registry. All setup notifications stay on
that Foundation page. Bifrost Sustainability has no setup page of its own.

Assign `BIFROST Sustain ori`, `BIFROST SustFull ori` or `BIFROST SustRead ori` alongside the appropriate Foundation
role. Foundation Full and Read already include the matching Sustainability set. The complete object allocation is
recorded in [.claude/CLAUDE.md](.claude/CLAUDE.md).

---

## Object ranges

| Object | Range |
| --- | --- |
| App (`app/`) | 70009200-70009249 |
| Test app (`test/`) | 98000-98099 |

---

## Message types

| Type | Effect | Retry behavior | Help |
| --- | --- | --- | --- |
| `Sustainability.Goal.Set` | Write: creates or updates a scorecard and the listed goals with the standard table rules; no posting, no Commit | Idempotent; a refusal rolls back the whole request | `Help.Implementation.Get` with subject `Sustainability.Goal.Set` |

## Documentation

All public documentation lives in the [businesscentralal/bifrost](https://github.com/businesscentralal/bifrost)
site repository and is published at <https://docs.bifrost.origo.is>.

| What | Where |
| --- | --- |
| Product documentation | <https://docs.bifrost.origo.is/en-us/sustainability/> |
| Bifröst documentation home | <https://docs.bifrost.origo.is> |
| Release notes | [CHANGELOG.md](CHANGELOG.md) |

---

## Dependencies

| App | ID | Publisher | Version |
| --- | --- | --- | --- |
| Bifrost Foundation | `7505e808-6e52-4b96-a328-82573391297a` | Origo | 28.0.11.0 |
| Sustainability | `b3780cd9-f8f8-4a83-a4d5-0c2ad87b28af` | Microsoft | 28.0.0.0 |

---

## Repository layout

| Folder | Content |
| --- | --- |
| `app/` | The AppSource app (`Bifrost Sustainability`), registration and permissions |
| `test/` | Test app (`Bifrost Sustainability - Tests`) |
| `tools/` | Pipeline guard scripts |
| `.AL-Go/`, `.github/`, `.alpaca/` | AL-Go for GitHub / COSMO Alpaca pipeline configuration |
