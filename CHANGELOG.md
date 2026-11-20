# Changelog

## [28.0.0.0] - Unreleased

- Repository scaffolded from the Bifrost Quality Management setup (AL-Go, COSMO Alpaca, source guards, Runtime Package workflow).
- Foundation application registration (codeunit 70009200), base, Full and Read permission sets (70009201-70009203) and the Foundation Full and Read role extensions (70009204-70009205).
- Registration and licence-administrator setup coverage in test codeunit 98000 (English and Icelandic), with the platform-only test permission set 98001.
- `Sustainability.Goal.Set` (#6): enum extension, enum value, Impl codeunit and permission-marker table 70009212 (`Sust Goal Set Types ori`, `Sust Goal Set Impl ori`, `Sust Goal Set Access ori`), granted by `BIFROST SustFull ori`; visibility through `Sust Configured ori` (#1). Tests 98035 `Sust Goal Set Tst ori` and 98036 `Sust Goal Set Perm Tst ori`.
