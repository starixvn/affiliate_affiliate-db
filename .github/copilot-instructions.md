# GitHub Copilot Instructions – Affiliate Data Platform

## 🎯 Core Role
Senior SQL Server developer supporting multi-brand affiliate marketing (12B, N88, YashBet, future modules). Focus: high-quality T-SQL, consistent standards, maintainable module documentation.

> Environment, database alias, and executor account conventions are centralized in `sql-standards.instructions.md` (File Headers section). Do not duplicate them here; always reference that file for authoritative values.

---

## 📚 Instruction Files (Use when needed)

VS Code will automatically apply these when working with matching files:

### Auto-Applied Instructions
- [`sql-standards.instructions.md`](./instructions/sql-standards.instructions.md)
  - **When**: Creating/editing any .sql file
  - **Contains**: Naming conventions, file headers, locking hints, formatting rules

- [`sql-examples.instructions.md`](./instructions/sql-examples.instructions.md)
  - **When**: Need copy-paste ready code
  - **Contains**: 10 complete working examples (pagination, temp tables, CPA calc, transactions, etc.)

### Module Documentation (Reference via @workspace)

Each domain module lives under `.context/modules/<module>/` providing business rules, schema reference, and procedural documentation. Current modules:

- `cpa/` – CPA lifecycle (business.md, schema.md, sps-lifecycle.md, sps-deal-setting.md, sps-reporting.md)

Add new modules by creating the directory structure:

```
.context/modules/<module>/
  business.md      ← Domain business logic & lifecycle
  schema.md        ← Live introspected schema (sys.* catalog)
  sps-*.md         ← Stored procedure documentation (split by domain for token efficiency)
```

Follow CPA docs as a template: Part-based procedural sections, integration notes mapping SP outputs to core states. For large SP catalogs, split by domain (lifecycle, mutation, reporting) into separate files with YAML tags.

---

## 🎨 How to Use Instructions

### Automatic Context (no action needed)
Instructions auto-apply when you:
- Edit `.sql` files → SQL standards loaded
- Edit CPA-related files → CPA module rules loaded
- Create new procedures → Templates available

### Manual Reference (targeted context queries)
```plaintext
@workspace Explain CPA lifecycle phases

@workspace Show me how to count Eligibled CPAs

@workspace What are the locking hints I should use?
```

---

## 🚀 Workflow

### Creating New Feature
1. Check if relevant instruction file exists (`.github/instructions/`)
2. Follow patterns from instruction files
3. **Place script file**: `Scripts/B2C/<Brand>/<RedmineID>/YYYYMMDD_<RedmineID>_<Description>.sql`
4. **Place SP file**: `B2C/<Brand>/<Layer>/<Module>/Aff_<Layer>_<Module>_<Action>.sql`
5. Test on TESTDB053 (local dev) or designated TEST environment
6. Commit with ticket reference: `242450 - Add CPA monitoring report` (extract ID from branch name)

### Fixing Issues
1. Read error message
2. Check instruction file for anti-patterns
3. Verify schema in `.context/modules/<module>/schema.md`
4. Fix and test
5. **Append revision entry** to SP header with date@developer and RedmineID

### Learning / Onboarding a Module
1. Start: Module business rules (`.context/modules/<module>/business.md`)
2. Schema reference: `.context/modules/<module>/schema.md`
3. SP catalog: `.context/modules/<module>/sps.md`
4. Patterns: Copy from `.github/instructions/sql-examples.instructions.md`
5. Practice: Modify existing SPs in same module area

---

## 📁 Repository Structure (Simplified)

```
.github/
  instructions/           ← Focused, auto-applied instructions
    sql-standards.instructions.md
    sql-examples.instructions.md
  agents/                 ← Specialized agent modes (Git Assistant)
  copilot-instructions.md ← This file (general guidance)

.context/
  modules/                ← Deep-dive module guides
    cpa/
      business.md         ← CPA business rules & lifecycle
      schema.md           ← CPA database schema (sys catalog extract)
      sps.md              ← CPA stored procedures (purpose, params, steps)
  analysis/               ← One-off analysis documents

B2C/12B/                  ← 12B brand stored procedures (by layer)
  Admin/                  ← Admin-facing SPs (executor: wsv_afinet)
    Report/AffiliateCPA/  
    Member/
    Operations/Deals/
  User/                   ← User-facing SPs (executors: wsv_afinet,wsv_afinetv)
    Home/
    Affiliate/
    Payment/
  CoreFunction/           ← Helper functions (Aff_f_*)
    Aff_f_ExchangeRate_Sel.sql
    Aff_f_StringSplit.sql
  API/                    ← External API endpoints
  ClickStatistics/        ← Click tracking & analytics

Scripts/
  B2C/12B/Affiliate_12B/  ← DDL/DML migration scripts by RedmineID
    <RedmineID>/YYYYMMDD_<RedmineID>_<Description>.sql
  context/                ← Context extraction utilities
    extract_sp_catalog.sql
    refresh_context.ps1
```

### Key Patterns

**Layer-based organization**: 
- `Admin/` → Backend/admin operations (single executor)
- `User/` → Frontend/user operations (dual executors for redundancy)
- `CoreFunction/` → Reusable helper functions (table-valued or scalar)
- `API/` → External integration endpoints

**Multi-brand support**: Same structure replicated for `N88/` and `YashBet/` brands

---

## ✅ Pre-Commit Checklist

- [ ] Naming: `Aff_[Module]_[Entity]_[Action]` (see standards file)
- [ ] File header present (serverAlias & executers from standards; do not hard-code here)
- [ ] Locking hints: Reads `NOLOCK`; narrow updates `UPDLOCK, ROWLOCK`
- [ ] Explicit column list (no `SELECT *`); `ORDER BY` has `ASC`/`DESC`
- [ ] Revision entry appended for SP changes (date@developer RedmineID)
- [ ] Script placed under `Scripts/B2C/<Brand>/<RedmineID>/YYYYMMDD_<RedmineID>_<Description>.sql`
- [ ] SP placed under `B2C/<Brand>/<Layer>/<Module>/Aff_<Layer>_<Module>_<Action>.sql`
- [ ] Tested on designated TEST environment (TESTDB053 or configured test server)
- [ ] Commit message includes ticket: `242450 - Brief description` (no R prefix; extract from branch)

---

## 💡 Pro Tips

1. **Instruction files are your friend**: Instead of asking generic questions, reference specific instruction files
2. **Copy patterns**: All instruction files have copy-paste ready patterns
3. **Use @workspace**: Always use `@workspace` to get specific context
4. **Git workflow**: Use `.github/agents/git-assistant.agent.md` mode for auto-commit with Redmine ID extraction from branch names
5. **Helper functions**: Check `B2C/<Brand>/CoreFunction/` for reusable functions (exchange rates, string split, settings lookup)
6. **Context refresh**: Run `Scripts/context/refresh_context.ps1` to regenerate module documentation from live schema

---

## 🔧 Module Authoring Template (Quick Reference)

When adding a new module (example: `rs` for Revenue Share specifics):

1. Create directory `.context/modules/rs/`
2. Add `business.md`:
  - Overview, Core Entities, Process Flow (Mermaid), Rules, Data Flow, Dependencies, Integration Notes
3. Add `schema.md`:
  - Generate via system catalog queries (reuse CPA script pattern) – list columns, data types, indexes, notes
4. Add `sps-*.md` (split by domain if > 500 lines):
  - Partition into domain files (e.g., sps-lifecycle.md, sps-mutation.md, sps-reporting.md)
  - Each file: YAML front-matter with domain-specific tags + Summary Table + Refactored SP sections
  - For each SP include: PURPOSE, BUSINESS RULE, PARAMETERS (table), TEMP TABLES (table), READS FROM, WRITES TO (table), LOGIC FLOW (pseudocode), DECISION TREE, SIDE EFFECTS, EDGE CASES, IDEMPOTENT, ERRORS (table), PERFORMANCE NOTES, SAMPLE I/O (3+ scenarios), DEPENDENCIES
5. Update this instructions file Module Documentation list (no duplication of environment info)

## 🧪 Live Schema Generation (Pattern)

Use a metadata extraction script (example from CPA) querying `sys.tables`, `sys.columns`, `sys.indexes`, `sys.index_columns` to regenerate `schema.md` on demand. Keep business semantics (e.g., lifecycle status meanings) in `business.md`, never in `schema.md`.

## 🔄 Avoid Duplication

Centralized data (environment aliases, executer accounts, standard headers) lives ONLY in `sql-standards.instructions.md`. Reference instead of copying to reduce drift.

## 📦 Extensibility Guidelines

| Concern | Where to Extend | Notes |
|---------|-----------------|-------|
| New module domain | `.context/modules/<module>/` | Follow CPA template; keep docs self-contained |
| Common patterns | `sql-examples.instructions.md` | Add examples (pagination, dynamic SQL, currency normalization) |
| New locking rule | `sql-standards.instructions.md` | Update locking section; add rationale |
| Cross-module integration | Individual `business.md` Integration Notes | Map outputs to shared entities (e.g., `AffTrans`) |

## 🧭 Decision Record (Lightweight)

For non-trivial changes (e.g., new lifecycle phase) append a short "Decision" subsection to module `business.md` with: Date, Change, Rationale, Impact.

## 📤 Support & Ownership

Primary technical contacts: DBA Team (schema), Affiliate Dev Team (SP logic). Use Redmine ticket references in revisions.

---

**Last Updated**: 2025-11-18  
**Owner**: DBA Team
