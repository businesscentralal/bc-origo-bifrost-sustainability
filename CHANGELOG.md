# Changelog

## [28.0.0.0] - Unreleased

- `Sustainability.Scorecard.Get` (enum extension 70009209, codeunit 70009209) reads a sustainability scorecard and its goals, with baseline, current, target and progress. Read only: it does not post.
- Shared visibility check `Sust Configured ori` (codeunit 70009206). A Sustainability type is visible when the emission unit of measure is set or a sustainability account exists.
- `BIFROST Sustain ori` (70009201) grants the registration, the visibility check and read on sustainability setup and account. `BIFROST SustRead ori` (70009203) adds execute on the scorecard reader and read on the scorecard, goal and ledger entry. `BIFROST SustFull ori` (70009202) includes the read set. The Foundation Read and Full role extensions grant those codeunits directly. They do not grant Microsoft table data (AppSourceCop AS0110/AS0112); the assignable sets do.
- Repository scaffolded from the Bifrost Quality Management setup (AL-Go, COSMO Alpaca, source guards, Runtime Package workflow).
- Foundation application registration (codeunit 70009200), base, Full and Read permission sets (70009201-70009203) and the Foundation Full and Read role extensions (70009204-70009205).
- Registration and licence-administrator setup coverage in test codeunit 98000 (English and Icelandic), with the platform-only test permission set 98001.
