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

**Message types:** `Sustainability.AccountBalance.Get` reads net change and balances for selected accounts.
`Sustainability.Journal.Create` creates unposted journal lines with manual emissions or formula inputs.
`Sustainability.Scorecard.Get` reads a scorecard and the progress of its goals.
`Sustainability.Journal.Check` validates a journal batch without changing it.
The first release adds the other reads, master-data writes and journal types listed in the release tracker.
Journal posting and ledger reversal come in release 2.

Foundation discovers this app on **Bifrost Setup** through its application registry. All setup notifications stay on
that Foundation page. Bifrost Sustainability has no setup page of its own.

Assign `BIFROST Sustain ori`, `BIFROST SustFull ori` or `BIFROST SustRead ori` alongside the appropriate Foundation
role. Foundation Full and Read receive this app's execute and capability grants; Microsoft table reads come from the assignable Sustainability sets or the user's existing Business Central roles. The complete object allocation is
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
| `Sustainability.AccountBalance.Get` | Read account net change and balance, including totals | Read-only and idempotent | [Contract](docs/account-balance.md) |
| `Sustainability.Journal.Create` | Write unposted lines; optionally create a batch | Every retry adds lines | `Help.Implementation.Get` |
| `Sustainability.Scorecard.Get` | Reads a scorecard and the baseline, current, target and progress of its goals. Posts nothing. | Idempotent. The same request reads the same rows. | [Scorecard](https://docs.bifrost.origo.is/en-us/sustainability/) |
| `Sustainability.Journal.Check` | Read | Idempotent; all validation changes roll back | Public message-type help, en-US and is-IS |

```json
{"type":"Sustainability.Journal.Create","data":{"templateName":"GENERAL","batchName":"DEFAULT","lines":[{"postingDate":"2026-01-15","documentNo":"SUST0001","accountNo":"1000","emissionCO2":10}]}}
```

The template must exist. `createBatch: true` creates a missing batch; otherwise the batch must exist too.
Each line requires `postingDate` and `accountNo`. `documentNo` defaults from the batch number series.
Supply either manual `emissionCO2`, `emissionCH4`, `emissionN2O`, or formula inputs `fuelOrElectricity`,
`distance`, `customAmount`, `installationMultiplier`, `timeFactor`. Native account/category/subcategory
validation calculates the emissions. Optional metadata: `description`, `unitOfMeasure`, `energySourceCode`,
`countryRegionCode`, `responsibilityCenter`, and `dimensions` (a map of dimension codes to value codes).

The response contains `lines`, each with `lineNo`, `CO2`, `CH4`, `N2O` and `CO2e`. CO2e uses Microsoft's
emission factors for the date, scope and country and is zero if no applicable factor exists.
Refusals use Foundation error `code` values and retain the named business refusal in `reason`:
`BatchNotFound` (`RecordNotFound`), `InvalidAccount` / `AmbiguousInput` (`InvalidParameter`),
and `ScopeMismatch` (`PreconditionFailed`). Unknown keys are refused. All lines, a newly created batch and any dimension sets belong to one transaction;
a validation failure leaves no partial data. This operation never posts a ledger entry. A successful retry
adds more lines, so check the previous result before retrying.

`BIFROST SustFull ori` grants the write and its empty capability table; Read does not. Visibility uses the
shared `Sust Configured ori` check: an emission unit of measure or at least one sustainability account,
and the caller's write permissions. Hidden means absent from the roster; a caller who knows the type
can still run it, subject to permissions and native validation.

### Check a sustainability journal

```json
{"type":"Sustainability.Journal.Check","data":{"templateName":"GENERAL","batchName":"DEFAULT"}}
```

Returns `status: Success`, `ready`, `lineCount`, and `journalErrors` containing `lineNo`, `fieldName`, and `message` from Microsoft's standard journal check. Empty batches return `ready: false`, zero lines and one explanatory message. Invalid lines also return `ready: false` with all collected errors. The check never posts or changes journal data; its transaction always rolls back and rejects explicit commits.

Unknown templates or batches return `RecordNotFound` with the requested codes and a corrective next step (the story's BatchNotFound reason). Unknown keys and invalid input are refused. Both names must be strings of 1–10 characters. Assign `BIFROST SustRead ori` and the required Business Central read permissions; a user lacking the capability receives `PermissionDenied` and cannot discover the type.

### When the Sustainability types are listed

The Sustainability message types are listed only in a company that uses Microsoft Sustainability: its Sustainability Setup has an Emission Unit of Measure Code, or at least one Sustainability Account exists. There is no switch of its own. The rule is read again on every call, so setting the company up (or clearing it) changes the list on the next call. Hidden means left out of the list only: a caller that knows a type can still run it. To block a type, use the Bifröst group settings. A user who cannot read Sustainability Setup or Sustainability Account does not see the types; the Bifrost Sustainability permission sets grant those reads, while users of the Foundation Full and Read roles need their own Sustainability permissions for them.

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
