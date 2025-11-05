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

- `cpa/` – CPA lifecycle (business.md, schema.md, sps.md)

Add new modules by creating the directory structure:

```
.context/modules/<module>/
  business.md      ← Domain business logic & lifecycle
  schema.md        ← Live introspected schema (sys.* catalog)
  sps.md           ← Stored procedure documentation (Purpose, Params, Steps, Writes, Idempotency)
```

Follow CPA docs as a template: Part-based procedural sections, integration notes mapping SP outputs to core states.

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
3. Test on TESTDB053
4. Commit with ticket reference: R123456 Description (replace R123456 with real ticket)

### Fixing Issues
1. Read error message
2. Check instruction file for anti-patterns
3. Verify schema in `.context/modules/cpa/schema.md`
4. Fix and test

### Learning / Onboarding a Module
1. Start: `.context/README.md`
2. Deep-dive: `.context/modules/cpa/*.md`
3. Patterns: Copy from instruction files
4. Practice: Modify existing SPs

---

## 📁 Repository Structure (Simplified)

```
.github/
  instructions/           ← Focused, auto-applied instructions
    sql-standards.instructions.md
    sql-examples.instructions.md
  copilot-instructions.md ← This file (general guidance)

.context/
  modules/                ← Deep-dive module guides
    cpa/
      business.md         ← CPA business rules
      schema.md           ← CPA database schema
      sps.md              ← CPA stored procedures

B2C/12B/
  Admin/                  ← Admin stored procedures
  User/                   ← User stored procedures
  CoreFunction/           ← Helper functions

Scripts/
  B2C/12B/Affiliate_12B/  ← DDL/DML scripts by RedmineID
```

---

## ✅ Pre-Commit Checklist

- [ ] Naming: `Aff_[Module]_[Entity]_[Action]` (see standards file)
- [ ] File header present (serverAlias & executers from standards; do not hard-code here)
- [ ] Locking hints: Reads `NOLOCK`; narrow updates `UPDLOCK, ROWLOCK`
- [ ] Explicit column list (no `SELECT *`); `ORDER BY` has `ASC`/`DESC`
- [ ] Revision entry appended for SP changes (date@developer RedmineID)
- [ ] Script placed under `Scripts/<Brand>/<Module>/<RedmineID>/`
- [ ] Tested on designated TEST environment
- [ ] Commit message includes ticket: R123456 Brief description (replace R123456)

---

## 💡 Pro Tips

1. **Instruction files are your friend**: Instead of asking generic questions, reference specific instruction files
2. **Copy patterns**: All instruction files have copy-paste ready patterns
3. **Use @workspace**: Always use `@workspace` to get specific context

---

## 🔧 Module Authoring Template (Quick Reference)

When adding a new module (example: `rs` for Revenue Share specifics):

1. Create directory `.context/modules/rs/`
2. Add `business.md`:
  - Overview, Core Entities, Process Flow (Mermaid), Rules, Data Flow, Dependencies, Integration Notes
3. Add `schema.md`:
  - Generate via system catalog queries (reuse CPA script pattern) – list columns, data types, indexes, notes
4. Add `sps.md`:
  - Partition into Parts (e.g., Lifecycle, Setting, Reporting)
  - For each SP include: Purpose | Parameters | Core Steps | Writes | Idempotency | Errors | Performance
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

**Last Updated**: 2025-11-12  
**Owner**: DBA Team
