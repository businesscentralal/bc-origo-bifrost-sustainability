# Sustainability.AccountBalance.Get

```json
{"type":"Sustainability.AccountBalance.Get","data":{"accountFilter":"1000..1999","fromDate":"2026-01-01","toDate":"2026-12-31","asOfDate":"2026-12-31","includeZero":false}}
```

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

The response has `status: Success` and an `accounts` array. Each row has `no`, `name`, invariant `accountType`, `indentation`, `netChange` and `balance`. Each amount object contains `co2`, `ch4`, `n2o`, `co2e`, `water`, `dischargedWater` and `waste`, retaining the stored unit. An empty selection succeeds with an empty array. An explicitly requested, unknown `accountNo` is refused.

| Refusal | Foundation code | Correction |
| --- | --- | --- |
| `AccountNotFound` | `RecordNotFound` | Select an existing account. |
| `InvalidFilter` | `InvalidParameterFormat` | Correct the received Business Central filter. |
| `InvalidPeriod` | `InvalidParameterFormat` or `InvalidParameter` | Use ISO dates and an ordered period. |
| `PermissionDenied` | `PermissionDenied` | Assign Foundation Read, including Sustainability Read. |
| `InvalidParameter` | `InvalidParameter` | Correct the key, JSON type or conflicting account selectors. |

The response includes the named `refusal` alongside Foundation's `code`, `error` and `nextStep`; the contract's error entries include `code`, `when` and `fix`. Unexpected native read errors retain Foundation's `BusinessCentralError`. Dates and booleans are strictly typed; `includeZero` must be a JSON Boolean. No business-data writes or `Commit()` occur in this implementation. Foundation may record message processing.
