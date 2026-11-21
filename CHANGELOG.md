# Changelog

## [28.0.0.0] - Unreleased

- Added `Sustainability.AccountBalance.Get`: native account net change, balance and totals with date, global-dimension and responsibility-center filters; stored CO2e is summed without recalculating emission factors. Added enum extension/value and implementation codeunit 70009208, Read-role grants, bilingual contracts and dispatcher tests in codeunit 98015.

- Repository scaffolded from the Bifrost Quality Management setup (AL-Go, COSMO Alpaca, source guards, Runtime Package workflow).
- Foundation application registration (codeunit 70009200), base, Full and Read permission sets (70009201-70009203) and the Foundation Full and Read role extensions (70009204-70009205).
- `Sustainability.Account.Set` (#14): enum extension and value 70009210, Impl codeunit 70009210 `Sust Account Set Impl ori` and capability table 70009210 `Sust Account Set Access ori` (granted by `BIFROST SustFull ori` and the Foundation Full role extension). Creates or updates a Sustainability Account through Validate, refuses a subcategory of another category or an unknown category (InvalidParameter), blocking an account with open journal lines (PreconditionFailed, naming the batches) and a missing number (MissingParameter); posts nothing (D2). Tests 98025 `Sust Account Set Tst ori` and 98026 `Sust Account Set Perm Tst ori`.
- Shared visibility check `Sust Configured ori` (codeunit 70009206, #1) used by `IsEnabled`; granted by the base set `BIFROST Sustain ori` and integrated from main.
- Foundation Full grants the Account.Set implementation and write capability; discovery can evaluate the type for Read users and return false without an execute-permission exception.
- Registration and licence-administrator setup coverage in test codeunit 98000 (English and Icelandic), with the platform-only test permission set 98001.
- Shared visibility check `Sust Configured ori` (codeunit 70009206, #1, Gunnar's decision D5): a company counts as configured when Sustainability Setup has an Emission Unit of Measure Code or at least one Sustainability Account exists; no read permission means not configured, never an error. `BIFROST Sustain ori` grants the codeunit and read on Sustainability Setup (6217) and Sustainability Account (6210). The Foundation Full and Read role extensions (70009204-70009205) now grant this app's own codeunits directly instead of including the Sustainability sets, so no Microsoft table data is added through a permission set extension (AppSourceCop AS0110/AS0112).
- Tests for the check: 98002 `Sust Configured Tst ori` (AC01-AC04), 98003 `Sust Configured Perm Tst ori` (AC05), 98005 `Sust Roster Tst ori` (AC06, English and Icelandic), with the test-only type `Sustainability.Test.Visibility` (enum extension and codeunit 98004).
