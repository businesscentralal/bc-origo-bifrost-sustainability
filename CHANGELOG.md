# Changelog

## [28.0.0.0] - Unreleased

- Fixed Full-role journal creation with open approvals by granting read access to User Setup. Permission tests now seed unrelated open approvals for another approver and cover native approval checks plus rollback without losing existing journal lines (#7).

- Added `Sustainability.Journal.Create`: atomic journal creation with native manual/formula validation, Full-only permissions, bilingual help and named refusals (#7). Added enum extension/value, implementation codeunit and capability table 70009213; test codeunits 98040-98041, fixture codeunit 98042 and test execution permission set 98043. No ledger posting.
- Added `Sustainability.AccountBalance.Get`: native account net change, balance and totals with date, global-dimension and responsibility-center filters; stored CO2e is summed without recalculating emission factors. Added enum extension/value and implementation codeunit 70009208, Read-role grants, bilingual contracts and dispatcher tests in codeunit 98015.

- Repository scaffolded from the Bifrost Quality Management setup (AL-Go, COSMO Alpaca, source guards, Runtime Package workflow).
- Foundation application registration (codeunit 70009200), base, Full and Read permission sets (70009201-70009203) and the Foundation Full and Read role extensions (70009204-70009205).
- Registration and licence-administrator setup coverage in test codeunit 98000 (English and Icelandic), with the platform-only test permission set 98001.
- Shared visibility check `Sust Configured ori` (codeunit 70009206, #1, Gunnar's decision D5): a company counts as configured when Sustainability Setup has an Emission Unit of Measure Code or at least one Sustainability Account exists; no read permission means not configured, never an error. `BIFROST Sustain ori` grants the codeunit and read on Sustainability Setup (6217) and Sustainability Account (6210). The Foundation Full and Read role extensions (70009204-70009205) now grant this app's own codeunits directly instead of including the Sustainability sets, so no Microsoft table data is added through a permission set extension (AppSourceCop AS0110/AS0112).
- Tests for the check: 98002 `Sust Configured Tst ori` (AC01-AC04), 98003 `Sust Configured Perm Tst ori` (AC05), 98005 `Sust Roster Tst ori` (AC06, English and Icelandic), with the test-only type `Sustainability.Test.Visibility` (enum extension and codeunit 98004).
