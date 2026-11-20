# Changelog

## [28.0.0.0] - Unreleased

- Repository scaffolded from the Bifrost Quality Management setup (AL-Go, COSMO Alpaca, source guards, Runtime Package workflow).
- Foundation application registration (codeunit 70009200), base, Full and Read permission sets (70009201-70009203) and the Foundation Full and Read role extensions (70009204-70009205).
- `Sustainability.EmissionSummary.Get` (#2): enum extension and value 70009207, Impl codeunit 70009207 `Sust Emission Sum Impl ori` and capability table 70009207 `Sust Emission Access ori`. Read-only summary of Sustainability Ledger Entry by emission scope, period (Day/Week/Month/Quarter/Year, at most 400) and gas, with optional water, waste and energy totals. Granted by `BIFROST SustRead ori`; `BIFROST SustFull ori` now includes `BIFROST SustRead ori`. Tests: codeunit 98010 `Sust Emission Sum Tst ori` and test permission set 98011 `Sust Msg Test ori`.
- Registration and licence-administrator setup coverage in test codeunit 98000 (English and Icelandic), with the platform-only test permission set 98001.
