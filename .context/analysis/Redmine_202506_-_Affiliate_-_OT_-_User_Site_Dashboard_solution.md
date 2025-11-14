# Redmine: 202506 - Affiliate - OT - User Site Dashboard

Updated: 2025-11-14

This document now reflects the ACCEPTED implementation (the "correct" version provided) of `Aff_User_Overview_Summary_Sel`. Earlier exploratory analysis (hybrid normalization, extra columns) has been superseded. Use this as the expected behavior reference going forward.

---

## Business Goal

Deliver a dashboard that shows combined Revenue Share and/or CPA KPIs for an affiliate over a selected window (monthly by default, optional arbitrary date range). It surfaces: signups, FDMs, deposits, turnover, commission, sub-affiliate metrics, click stats, GGR, and CPA metrics (approved, tentative, qualified). Deal type resolution drives conditional UI rendering.

## Stored Procedure Signature (Final)

```sql
CREATE PROCEDURE dbo.Aff_User_Overview_Summary_Sel
(
    @AffId INT,
    @FromDate SMALLDATETIME,
    @ToDate SMALLDATETIME,
    @BaseCurrency INT = 0,
    @IsGetMonthly BIT = 1
)
-- (Body summarized below; see source for full logic)
```

Semantics:
- `@IsGetMonthly = 1`: Caller supplies a month window (FromDate .. ToDate) inclusive; procedure uses commission boundary to split finalized vs unfinalized portions for revenue share.
- `@IsGetMonthly = 0`: Arbitrary date range; revenue share ActivePlayers/QualifiedMember are derived directly from `rptMemberDaily` (no commission engine) while other monthly-only metrics still aggregate over the raw window.
- `@BaseCurrency`: Target conversion currency (mapped via `TpExchange` + `Aff_f_ExchangeRate_Sel`).

## Key Data Sources

- Revenue Share (monthly finalized/unfinalized): `Aff_Commission_Calc`, `Aff_Commission_UnCalc`.
- Date-range RS player stats: `rptMemberDaily` (with clustered temp table + month bucket EOMONTH).
- Deposits: Split logic — historical via `rptMemberDaily`, current via `bodb_12B.dbo.DepositInfo` (using GMT offsets and commission boundary `AFF_CommissionDate`).
- CPA: `MemberCPA` (StatusId 2 = Eligible, 3 = Settled) plus current `AffGroupHistory` and `CommGroup` for deal type and quota.
- Click stats: `ClickStatistics` + archive table `ClickStatistics_bk` with GMT+8 → GMT-4 conversion and exclusion filter `IsExcluded = 0`.

## Deal Type Resolution (GroupType)

Logic sets `@GroupTypeName` default 'Hybrid'. It evaluates overlapping `AffGroupHistory` rows for the selected window:
- If no overlapping non-CPA groups (no `GroupTypeId <> 3`) → 'CPA'.
- If no overlapping non-Revenue groups (no `GroupTypeId <> 1`) → 'Revenue'.
- Else remains 'Hybrid'.

This is a simplified classification (not day-by-day coverage). Hybrid means both RS and CPA data are potentially relevant.

## Revenue Share Logic (Monthly Mode)

When `@IsGetMonthly = 1`:
1. Split month window around `@MaxCommDate` (system setting `AFF_CommissionDate`).
2. If any portion after boundary: call `Aff_Commission_UnCalc` for tentative part.
3. If any portion before/equal boundary: call `Aff_Commission_Calc` for finalized part.
4. Accumulate into `#TempCommission` then sum ActivePlayer, QualifiedMember, Turnover, Commission, SubAffCommission, NetWinloss (NetGGR).

## Revenue Share Logic (Date-Range Mode)

When `@IsGetMonthly = 0`:
1. Build `#DataMemberDaily` aggregating per (MonthDate, AffId, Currency, CustId, ProductId) excluding `MemberRemoval`.
2. Map affiliate/month to group history for QM Turnover via `CommGroupHistory` then apply exchange rate.
3. Derive ActivePlayer (distinct CustId with productId > 0) and QualifiedMember (per-cust turnover >= QM turnover) and insert synthesized rows into `#TempCommission` (other monetary fields become 0 except GGR components from aggregated win/loss adjustments).

## Deposits

Two paths depending on date intersection with commission boundary:
- After boundary (current part): live `DepositInfo` (GMT0 data adjusted to GMT+8; currency scaling for VND/IDR; exclude removed members using converted local date).
- Before boundary (historical part): `rptMemberDaily` with month-bucket grouping.
Date-range mode aggregates directly over `rptMemberDaily` for entire window.

## CPA Metrics

Variables: `@ApprovedCPAAmount`, `@TentativeCPAAmount`, `@QualifiedMemberCPA`, `@RemainQuota`, `@Quota`.

Steps:
1. Current group determined from `AffGroupHistory` row where `ToDate = '9999-12-31'` (open-ended) — this supplies the active `GroupId` and associated quota (`CPAGroupSetting` not directly joined here; quota taken from `CommGroup` mapping with 0 translated to NULL for unlimited).
2. Approved CPA: SUM(CPAAmount) & COUNT(CustId) for StatusId = 3 where `CPADate BETWEEN @FromDate AND @ToDate`.
3. Remaining quota: `@Quota - (COUNT settled StatusId=3 ALL TIME for current group)` — note: not date-filtered, represents cumulative consumption.
4. QualifiedMemberCPA: For current month only (`MONTH(@ToDate) = MONTH(@CurrentDate)`), add eligible candidates (StatusId=2, `HoldingQualifiedDate <= @ToDate`), capped by remaining quota (unlimited if quota NULL).
5. Tentative CPA Amount: Top N (N = remaining quota or unlimited) eligible rows ordered by `HoldingQualifiedDate, FirstDepositDate, MemberCPA_ID` sum CPAAmount.

Past months: QualifiedMemberCPA reflects only settled players (no tentative addition) due to month check constraint.

## Click Statistics

Select current vs archived tables with date-window split around archive cutoff (`ArchiveDate_ClickStatistics`). Convert selected window to GMT-4 for comparisons, apply `[Date]` range and `IsExcluded = 0`. Distinct IP count yields UniqueClick.

## Returned Columns (Final)

```text
Signups,
DepositedMembers,
BalanceBroughtForward,
ActivePlayers,
QualifiedMember (Revenue Share),
Turnover,
Deposit,
Commission,
NoOfSubAff,
SubAffCommission,
FDMDeposit,
NetGGR,
TotalClick,
UniqueClick,
ApprovedCPAAmount,
TentativeCPAAmount,
QualifiedMemberCPA (CPA),
GroupType ("CPA" | "Revenue" | "Hybrid")
```

Note: There is no separate `QualifiedRevenueSharePlayers` or `SubAffiliateEarning` column in this version; legacy `QualifiedMember` covers RS qualification.

## Differences vs Earlier Draft (Deprecated)

| Aspect | Earlier Draft | Final Implementation |
|--------|---------------|---------------------|
| Param Order | AffId, IsGetMonthly, From/To, BaseCurrency | AffId, FromDate, ToDate, BaseCurrency, IsGetMonthly (default 1) |
| Date Normalization | Forced recompute of month bounds | Uses supplied From/To directly; splits commission month via MaxCommDate |
| Group Type | Day-span intersection classification | Simplified absence-based checks; default Hybrid |
| Quota Source | CPAGroupSetting range intersection | Current open `AffGroupHistory` + CommGroup (Quota 0→unlimited) |
| RS Date-Range | Complex per-month re-routing via engines | Direct rptMemberDaily aggregation (Active/Qualified only) |
| CPA Qualified Logic | Settled + min(eligible, remaining quota) both for current/past | Adds eligible only for current month; past months show settled only |
| Outputs | Many new columns (QualifiedRevenueSharePlayers, SubAffiliateEarning, GroupTypeName) | Lean set listed above |

## Implementation Notes / Caveats

- Remaining quota subtraction not date-scoped: large historical settled volume can reduce current month eligibility early.
- CPA group detection assumes single open-ended row; if multiple overlapping rows appear logic may misclassify.
- Commission boundary split uses two engine calls only in monthly mode; date-range does not consult engines at all (turnover/commission zeros).
- Inclusive end comparison for some filters uses `<= @ToDate`; others use `< DATEADD(DAY,1,@ToDate)` semantics — current code mixes styles (e.g., CPADate BETWEEN inclusive; signup uses `< DATEADD(DAY,1,@ToDate)`). Standardization could be future improvement.

## Potential Future Enhancements

1. Normalize inclusive/exclusive end-date handling across all sections.
2. Refine GroupType classification to day-level coverage with potential partial-month Hybrid labeling.
3. Date-range revenue share commission (optional) by synthesizing month buckets and invoking engines per bucket to surface turnover-based commission outside monthly mode.
4. Quota logic date-scope: limit settled CPA count to current month to avoid historical exhaustion impact (requires business sign-off).

## Index / Performance Recommendations

- If CPA volume grows: add nonclustered indexes `MemberCPA (AffId, StatusId, CPADate)` and `MemberCPA (AffId, StatusId, HoldingQualifiedDate)`.
- Consider covering index on `rptMemberDaily (AffId, WinlostDate)` if date-range usage expands.
- Archive click IP logic already split; monitor size of `ClickStatistics_bk` for potential partitioning.

---
This document supersedes the earlier speculative analysis for Redmine 202506. Any future changes should append a decision record section here with Date / Change / Rationale.
