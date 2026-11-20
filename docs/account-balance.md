# Sustainability.AccountBalance.Get

```json
{"type":"Sustainability.AccountBalance.Get","data":{"accountFilter":"1000..1999","fromDate":"2026-01-01","toDate":"2026-12-31","asOfDate":"2026-12-31","includeZero":false}}
```

Planned contract for issue #3; implementation and verification are in progress.
Returns account identity, account type and indentation with net change and balance for CO2, CH4, N2O, CO2e, water, discharged water and waste.

| Parameter | Meaning |
| --- | --- |
| `accountNo` | Optional exact account number; cannot be combined with `accountFilter`. |
| `accountFilter` | Optional Business Central account-number filter; omission selects every account. |
| `fromDate`, `toDate` | Optional inclusive net-change bounds in ISO date format. |
| `asOfDate` | Optional inclusive balance date; defaults to `toDate`, otherwise all dates. |
| `globalDimension1Filter`, `globalDimension2Filter` | Optional Business Central global-dimension filters. |
| `responsibilityCenterFilter` | Optional Business Central responsibility-center filter. |
| `includeZero` | Include accounts with zero net change and balance; defaults to false. |

Microsoft's account FlowFields supply six measures. CO2e uses the stored ledger amount with the same account/Totaling, date and dimension selection. It does not recalculate emission factors. Totals use the account's Totaling expression. Nothing posts or changes sustainability data.

Unknown account, malformed filter and invalid period refusals are named `AccountNotFound`, `InvalidFilter` and `InvalidPeriod`. Foundation's stable error codes accompany those refusal names and translated guidance. Unknown request keys are refused.

The Read role grants the implementation and native table reads. The shared visibility check from #1 controls catalogue visibility; a hidden type can still be called by name if the caller has permission.
