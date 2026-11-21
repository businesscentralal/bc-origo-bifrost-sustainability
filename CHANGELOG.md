# Changelog

## [28.0.0.0] - Unreleased

- Use Foundation `RecordNotFound` and `PreconditionFailed` for preview refusals, with the requested template/batch in missing-batch diagnostics. Public help regression coverage validates the complete contract in English and Icelandic (Architect clarification of #9 AC04).

- Add `Sustainability.Journal.PreviewPost` (enum extension/value, capability table and implementation 70009215; rollback adapter codeunit 70009227), with translated contracts, input refusals and preview totals. Posting uses temporary journal lines and rolls back after the standard approval check, before deletion; Read users need no journal-delete permission. Number-series changes roll back. Dispatcher coverage is in test codeunit 98050 with permission fixture 98051.

- Added `Sustainability.Journal.Check` (#8): enum extension/value, implementation and capability table 70009214, rollback runner codeunit 70009228. Uses the standard batch validator, returns all line errors, treats empty batches as not ready and commits no journal or ledger changes. Includes Foundation Read/Full capability grants, bilingual help, and dispatcher/rollback tests 98045–98047.
- Added `Sustainability.AccountBalance.Get`: native account net change, balance and totals with date, global-dimension and responsibility-center filters; stored CO2e is summed without recalculating emission factors. Added enum extension/value and implementation codeunit 70009208, Read-role grants, bilingual contracts and dispatcher tests in codeunit 98015.

- Repository scaffolded from the Bifrost Quality Management setup (AL-Go, COSMO Alpaca, source guards, Runtime Package workflow).
- Foundation application registration (codeunit 70009200), base, Full and Read permission sets (70009201-70009203) and the Foundation Full and Read role extensions (70009204-70009205).
- Registration and licence-administrator setup coverage in test codeunit 98000 (English and Icelandic), with the platform-only test permission set 98001.
- Shared visibility check `Sust Configured ori` (codeunit 70009206, #1, Gunnar's decision D5): a company counts as configured when Sustainability Setup has an Emission Unit of Measure Code or at least one Sustainability Account exists; no read permission means not configured, never an error. `BIFROST Sustain ori` grants the codeunit and read on Sustainability Setup (6217) and Sustainability Account (6210). The Foundation Full and Read role extensions (70009204-70009205) now grant this app's own codeunits directly instead of including the Sustainability sets, so no Microsoft table data is added through a permission set extension (AppSourceCop AS0110/AS0112).
- Tests for the check: 98002 `Sust Configured Tst ori` (AC01-AC04), 98003 `Sust Configured Perm Tst ori` (AC05), 98005 `Sust Roster Tst ori` (AC06, English and Icelandic), with the test-only type `Sustainability.Test.Visibility` (enum extension and codeunit 98004).
