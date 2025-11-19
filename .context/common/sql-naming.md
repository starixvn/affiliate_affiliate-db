# SQL Naming Conventions

This document centralizes the naming conventions for stored procedures, functions, tasks, and other SQL objects used in the Affiliate DB repositories. It is intentionally placed under `.context/common` so templates and environment documentation can reference a single source of truth.

## Stored Procedures

Pattern: `Aff_[Layer]_[Module]_[Entity]_[Action]` or `Aff_[Layer]_[Entity]_[Action]`

Layer prefixes:

- `Aff_Admin_*` - Admin procedures (executor: `wsv_afinet`)
- `Aff_User_*` - User procedures (executors: `wsv_afinet,wsv_afinetv`)
- `Aff_API_*` - API endpoint procedures
- `Aff_ClickStatistics*` - Click tracking (note: no underscore after prefix)
- `Aff_Con_*` - Security/UserControl procedures
- `Aff_f_*` - Helper functions (table-valued or scalar)
- `Task_Aff_*` - Scheduled jobs

Action suffixes:

- `_Sel` - SELECT
- `_Ins` - INSERT
- `_Upd` - UPDATE
- `_Del` - DELETE

Examples:

```text
Aff_Admin_Report_PlayerCPA_Sel
Aff_User_Overview_Summary_Sel
Aff_f_ExchangeRate_Sel
Task_Aff_CPAActivePeriod
```

## Functions

- Use `Aff_f_[Purpose]` for reusable functions.
- For nested/internal-only functions, set `isNested="1"` in metadata (see templates).

## Files and Scripts

- Migration scripts: `Scripts/B2C/<Brand>/<RedmineID>/YYYYMMDD_<RedmineID>_<Description>.sql`
- Stored procedures: `B2C/<Brand>/<Layer>/<Module>/Aff_<Layer>_<Module>_<Action>.sql`

## Why place in `.context/common`?

- Keeps naming rules centralized and easy to reference by tooling and templates.

---
**Last Updated**: 2025-11-19
**Owner**: DBA Team
