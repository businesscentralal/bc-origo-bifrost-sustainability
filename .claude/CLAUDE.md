# Extension: Bifrost Sustainability

## Customer
Origo / AppSource

## Prefix
(none - objects use raw names with the mandatory `ori` suffix inside the `Origo.Bifrost.Sustainability` namespace; same as Bifrost Subscription Billing and Bifrost Quality Management. Short object-name stem: `Sust`)

## Namespace
Origo.Bifrost.Sustainability (tests: Origo.Bifrost.Sustainability.Test)

## Object ID Range
App:   70009200-70009249 (one contiguous 50-ID block, Gunnar's decision D7 on 20.11.2026)
Tests: 98000-98099

The app block is small. Allocate IDs densely and record every allocated id here as objects are created.

| Object | ID | Name |
| --- | --- | --- |
| Codeunit | 70009200 | Sust Registration ori |
| Permission set | 70009201 | BIFROST Sustain ori (base) |
| Permission set | 70009202 | BIFROST SustFull ori |
| Permission set | 70009203 | BIFROST SustRead ori |
| Permission set extension | 70009204 | Sust Full Role ori (extends `BIFROST Full ori`) |
| Permission set extension | 70009205 | Sust Read Role ori (extends `BIFROST Read ori`) |
| Test codeunit | 98000 | Sust Scaffold Tst ori |
| Test permission set | 98001 | Sust Setup Test ori |
| Codeunit | 70009206 | Sust Configured ori (shared visibility check, D5, #1) |
| Test codeunit | 98002 | Sust Configured Tst ori |
| Test codeunit | 98003 | Sust Configured Perm Tst ori |
| Test enum extension + value + codeunit | 98004 | Sust Visibility Probe ori (`Sustainability.Test.Visibility`, test-only) |
| Test codeunit | 98005 | Sust Roster Tst ori |
| Enum extension / enum value | 70009213 | Sust Jnl Create ori / Sustainability.Journal.Create |
| Codeunit | 70009213 | Sust Jnl Create Impl ori |
| Capability table | 70009213 | Sust Jnl Create Cap ori |
| Test codeunit | 98040 | Sust Jnl Create Tst ori |
| Test codeunit | 98041 | Sust Jnl Create Perm Tst ori |
| Test fixture codeunit | 98042 | Sust Jnl Create Fixture ori |
| Test permission set | 98043 | Sust Jnl Exec ori |
| Enum extension/value | 70009208 | Sust Account Balance ori / Sustainability.AccountBalance.Get |
| Codeunit | 70009208 | Sust Account Bal Impl ori |
| Test codeunit | 98015 | Sust Account Balance Tst ori |

Reserved for the release 1 issues (one number per message type; the enum extension, its enum value, the Impl
codeunit and any capability table of a type all use that type's number, since they are different object types):

| ID | Reserved for | Test ids |
| --- | --- | --- |
| 70009206 | Sust Configured ori (shared visibility check, D5) | 98002-98009 |
| 70009207 | Sustainability.EmissionSummary.Get | 98010-98014 |
| 70009208 | Sustainability.AccountBalance.Get | 98015-98019 |
| 70009209 | Sustainability.Scorecard.Get | 98020-98024 |
| 70009210 | Sustainability.Account.Set | 98025-98029 |
| 70009211 | Sustainability.Category.Set | 98030-98034 |
| 70009212 | Sustainability.Goal.Set | 98035-98039 |
| 70009213 | Sustainability.Journal.Create | 98040-98044 |
| 70009214 | Sustainability.Journal.Check | 98045-98049 |
| 70009215 | Sustainability.Journal.PreviewPost | 98050-98054 |
| 70009216 | Sustainability.Journal.Post (release 2) | 98055-98059 |
| 70009217 | Sustainability.LedgerEntry.Reverse (release 2) | 98060-98064 |
| 70009218 | Sustainability.Journal.Update | 98065-98069 |

A type that needs a second object of the same type (for example a helper codeunit) takes the next free number
from 70009219 upwards and records it here in the same PR. Next free app id: 70009219. Next free test id: 98070.

## Microsoft source
Wrapped Microsoft app: Sustainability (`b3780cd9-f8f8-4a83-a4d5-0c2ad87b28af`, floor 28.0.0.0). Source:
https://github.com/microsoft/BCApps/tree/main/src/Apps/W1/Sustainability (open source since `releases/29.0`; the 28.x
objects are the same tables, read their symbols). Read it there before designing message types.

## Release 1 scope (Gunnar's decisions 20.11.2026)
- D1: the MVP is the 12 `Sustainability.*` types in the plan, one issue each.
- D2: **no posting in release 1.** Reads, master data and journal lines first. `Sustainability.Journal.Post` and
  `Sustainability.LedgerEntry.Reverse` are release 2. In release 1 nothing may commit a posting: `Sustainability Jnl.-Post`
  runs only inside the posting-preview framework (`Sustainability.Journal.PreviewPost`, which rolls back), and
  `Sustainability Recur Jnl.-Post` and `Sust. Entry Reverse Mgt.` are not called at all.
- D3: CBAM, EPR and excise are later. D4: Copilot emission calculation is out of scope. D8: ESG/CSRD reporting is release 2.
- D5: visibility is automatic. A type is visible (`IsEnabled`) when `Sustainability Setup."Emission Unit of Measure Code"`
  is filled in **or** at least one Sustainability Account exists. Hidden means roster-only: a caller that knows the type
  can still run it. Every type uses the one shared visibility check.
  Every type's `IsEnabled` returns `Sust Configured ori`.IsConfigured(). Microsoft table data is granted in the
  assignable Sustainability sets only, never through the Foundation role extensions (AS0110/AS0112 would fail CI).
- D6: minimum BC 28.0 (application 28.0.0.0, Sustainability 28.0.0.0), same as Foundation.

## Setup Notifications
Setup notifications live **only** on Bifröst Foundation's `Setup ori` page. This app never raises a `Notification` of its own.
It makes itself known to Foundation by subscribing to `App Registry ori.OnRegisterApps` and calling `AddApp` with this
app's module id, its display name and its setup page id (`0` while the app has no setup page). See
`app/src/Common/SustRegistration.Codeunit.al`.

## Target BC Version
28.0 (application 28.0.0.0, platform 28.0.0.0, runtime 17.0)

## Source Control
Platform: GitHub
Organization: businesscentralal
Repository: bc-origo-bifrost-sustainability
Default branch: main

## Dependencies
- Bifrost Foundation (`7505e808-6e52-4b96-a328-82573391297a`, 28.0.11.0, same floor as Bifrost Subscription Billing)
- Sustainability (Microsoft, `b3780cd9-f8f8-4a83-a4d5-0c2ad87b28af`, 28.0.0.0)

## Naming Rules
- Every object carries the `ori` suffix (AppSource mandatory affix), max 30 characters.
- The brand name "Bifrost" lives in the namespace, the app name ("Bifrost Sustainability"), the permission sets and
  user-facing captions - never as an object-name prefix.
- Message type names have three parts: `Domain.Entity.Action`, domain `Sustainability`.
- Icelandic captions use "Bifröst".

## Development Standards

This project follows the **Origo BC Development Standards** (https://github.com/OrigoSoftwareSolutions/bc-dev-standards).

Before writing any AL code, load the relevant skills: `origo-bc-al-coding-standards`, `origo-bc-test-writer`, `origo-bc-documentation-writer`.

Key rules always in effect:
- Namespace `Origo.Bifrost.Sustainability` at the top of every app file (`Origo.Bifrost.Sustainability.Test` in tests)
- XML documentation on every object and non-local procedure
- Bilingual captions (en-US + is-IS) on all user-facing text
- `SetLoadFields` where it pays (see the standards' exception list)
- `Format(guid, 0, 4)` for GUIDs, `Format(value, 0, 9)` / `Evaluate(var, text, 9)` for culture-invariant serialization
- Never use `Format()` / `Evaluate()` on enum values - use `.Names()`, `.Ordinals()`, `.AsInteger()`, `.FromInteger()`
- Implementation = code + tests + documentation (the contract chapters of `Msg Contract ori`)

## Development Environment
- COSMO Alpaca containers are defined in `app/.vscode/launch.json` (git-ignored, the authority for instance ids).
- Compile locally with alc.exe + CodeCop/UICop/AppSourceCop; AL-Go CI is the gate for AppSource affix rules (AS0011).
- `app/AppSourceCop.json` sets `mandatoryAffixes`/`mandatorySuffix` to `ori` and the supported countries.
- Reference implementations: Bifrost Subscription Billing and Bifrost Quality Management.

## Message Type Conventions
- One enum extension of Foundation's `Message Type ori` with one value per type, named `Domain.Entity.Action`. These
  keys are the published external API contract and must never be renamed or removed.
- Each type has an Impl codeunit implementing `Msg Interface ori`, `Msg Discovery ori` and `Msg Contract ori`, with
  `TableNo = "Message Argument ori"` and an `OnRun` that runs its own write, as in Bifrost Subscription Billing.
- Errors are returned as `status = Error` with a helpful message; never let an unhandled exception reach the API.
- Help text is public. Follow the Bifröst documentation rules: no customer names, tenant ids, internal hosts or
  credentials in help, contract chapters or examples.

## Test App Rules
- The test app uses Bifröst Foundation's public API only. Run message types through the public `Dispatcher ori`.
- Every message type is tested in W1 and IS, in languages 1033 and 1039.
- Unit tests never need credentials; this app makes no external calls.

## Testing Through the MCP Server
- Keep MCP calls serial - parallel bursts crash the server.
