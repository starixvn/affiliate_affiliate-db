# Redmine: 202506 - Affiliate - OT - User Site Dashboard

Generated: 2025-11-13

This document is the analysis-only solution proposal for the Redmine wiki "202506 - Affiliate - OT - User Site Dashboard". It follows the repository prompt instructions and is intended for pair-programming review. Do NOT apply any SQL changes until this solution is approved.

---

## Business Goal

Provide a unified, adaptive Affiliate User Site Dashboard that displays the correct KPIs depending on the affiliate's active deal type (Revenue Share, CPA, or Hybrid) and user-selected time scope (Month vs Date Range). Show tentative vs finalized earnings correctly (month-to-date tentative values for current month), quota-aware CPA progression, sub-affiliate metrics, and consistent timezone handling (GMT+8 primary view). The UI will show/hide fields by GroupTypeName returned from the DB.

## Affected Modules (tables / SPs / jobs / views)

- Tables: `MemberInfo`, `AffInfo`, `rptMemberDaily`, `ClickStatistics`, `ClickStatistics_bk`, `MemberCPA`, `MemberCPATier`, `MemberCPAProduct`, `AffTrans`, `rptAffiliateCPA`, `CommGroup`, `CPAGroupSetting`, `CPATierSetting`, `CPAProductSetting`, `AffGroupHistory`, `MemberRemoval`, `TpExchange`, `Exchange`, `GroupType`, `AffTransSubDetail`.
- Stored Procedures / Functions referenced: `Aff_User_Overview_Summary_Sel` (target), `Aff_Commission_Calc`, `Aff_Commission_UnCalc`, `Task_Aff_*` (CPA jobs e.g., Task_Aff_CPAApprovalPeriod), `Aff_f_ExchangeRate_Sel`, `Aff_f_GetSetting`, `Aff_f_AffGroupInfo_Sel`.
- Reporting: `rptMemberDaily`, `rptAffiliateCPA` are read sources; `AffTrans` used for BBF and approval linkage.

## Key Logic / Rule (SQL pseudocode / steps)

1. Time-scope normalization (UI supplies mode):
      - If IsGetMonthly = 1: FromDate = BeginOfMonth, ToDate = EndOfMonth (for past month) OR ToDate = CurrentDate (GMT+8) for current month.
             - IMPORTANT: when migrating from `@MonthDate` to the new parameter set `@IsGetMonthly, @FromDate, @ToDate`, be aware this affects many parts of this stored procedure (and other SPs) that depend on month semantics (notably revenue share calculation SPs). This migration is NOT limited to the `IsGetMonthly = 1` branch: every reference, filter, or calculation that previously used `@MonthDate` or assumed month-bound semantics must be reviewed and updated to use the normalized `@FromDate/@ToDate` pair (or derived BeginOfMonth/EndOfMonth) consistently.
                  - Areas to update include (non-exhaustive):
                     - Any code that derived BeginOfMonth/EndOfMonth from `@MonthDate` — replace with derived values from `@FromDate` when `IsGetMonthly=1`.
                     - Commission engine routing (BeginOfMonth <= `@MaxCommDate`) — ensure the BeginOfMonth used is the derived value.
                     - All date filters applied to `rptMemberDaily`, `AffTrans`, `MemberCPA`, `ClickStatistics` and other reporting sources that previously referenced `@MonthDate` should now use `@FromDate`/`@ToDate` or BeginOfMonth/EndOfMonth as appropriate.
                     - Any UI-mode assumptions (month-only views) must be enforced or validated by the SP (defensive checks) and not assumed silently.
                     - Tests, sample queries, and any documentation sections that mention `@MonthDate` must be updated.
     - Web behavior: when `@IsGetMonthly = 1` the web client will always send a FromDate/ToDate pair that covers exactly one calendar month (for example, `2025-09-01` to `2025-09-30`). The UI will not send multi-month ranges for monthly mode.
     - Defensive SP validation: the stored procedure should still validate that `FromDate` and `ToDate` form a single calendar month when `IsGetMonthly = 1` and return a clear error if not.
  - If IsGetMonthly = 0: FromDate and ToDate are taken directly from UI (validate not-null).

2. Determine affiliate deal type (GroupTypeName):
      - Prefer `AffGroupHistory` rows that intersect the filter window (use AffGroupHistory.FromDate / ToDate coverage inside the filter range). Evaluate all GroupTypeIds present across the filter window:
         - If all days in the filter window map to the same GroupType (e.g., CPA only) then return that GroupTypeName and render the SPA as that dashboard type.
         - If multiple GroupTypeNames appear across the filter window (e.g., CPA from day 1–10, RS 11–20, Hybrid 21–30), classify as `Hybrid` and show both RS and CPA columns.
      - Fallback: infer from commission temp outputs (turnover/commission > 0) and presence of `MemberCPA` rows if no AffGroupHistory snapshot is available.

   Examples:
   - If FromDate..ToDate (1–30) contains only `GroupType = CPA` => CPA dashboard only (show CPA columns only).
   - If FromDate..ToDate contains mixed group types => Hybrid dashboard (show both RS and CPA columns).

3. Revenue Share path (RS-only or HYB):
   - Use the commission engine for Revenue Share metrics. Which engine is used depends on the commission-finalization boundary (`MaxCommDate`):
      - If the month being requested (BeginOfMonth) is on or before the system `@MaxCommDate` then use `Aff_Commission_Calc` (finalized/calculated months) for authoritative outputs.
      - If the month being requested is after `@MaxCommDate` then use `Aff_Commission_UnCalc` to produce tentative/unfinalized metrics (month-to-date values).
      - Note: This routing must be applied after Time-scope normalization (the SP should derive BeginOfMonth when `IsGetMonthly = 1`) and before aggregating commission temp tables.
   - Aggregate ActivePlayers, QualifiedPlayers (from commission temp), Commission (final/tentative), NetRevenue = GrossWinloss - (PlatformFee + DepositFee + WithdrawalFee + Bonus + Rebate).

   - Note (Date-range / `IsGetMonthly = 0`): the dashboard must compute ActivePlayers and QualifiedPlayers differently when the user selects an arbitrary date range (not a single month). The `Aff_Admin_AffiliateReport_Sel` procedure contains the canonical implementation for this case — reuse the same pattern to ensure consistent numbers across admin reports and the user dashboard. Key points:
      - Source: `rptMemberDaily` is used as the authoritative per-day/per-cust source for date-range mode (grouped into month-buckets using `EOMONTH(r.WinlostDate)` in the reference SP).
      - ActivePlayers (date-range): COUNT DISTINCT CustId where productId > 0 (after product filters) within the WinlostDate window.
      - QualifiedPlayers (date-range): per-cust turnover (SUM(Turnover * exchangeRate) per CustId) compared against the per-aff `QMTurnover` (from `CommGroupHistory` for the relevant month-bucket). Count distinct CustId with Turnover >= QMTurnover.

   - Implementation sketch to add into the `IF(@IsGetMonthly = 0)` branch of `Aff_User_Overview_Summary_Sel`:
      1. Create `#DataMemberDaily` by selecting from `dbo.rptMemberDaily` filtered on `r.WinlostDate >= @FromDate AND r.WinlostDate < DATEADD(DAY, 1, @ToDate)`, excluding MemberRemoval rows, grouping by `CONVERT(SMALLDATETIME, EOMONTH(r.WinlostDate)), r.AffId, Currency, CustId, r.ProductId` and summing Bonus, Rebate, Turnover, Winloss.
      2. Build `@AffInfo` (AffId, MonthDate, GroupId) from distinct AffId/MonthDate in `#DataMemberDaily`, join `AffInfo` and `AffGroupHistory`, then populate `QMTurnover` by joining `CommGroupHistory` and applying `Aff_f_ExchangeRate_Sel`.
      3. Build `#ProductSetting` (DeductionSettingHistory filtered by product list) and derive `CTE_DataFilter` which is `#DataMemberDaily` LEFT JOIN `#ProductSetting` (keep rows where product applies or productId = -1).
      4. Compute `CTE_ActivePlayer`:
         - SELECT AffId, MonthDate, COUNT(DISTINCT IIF(productId > 0, CustId, NULL)) AS ActivePlayer FROM CTE_DataFilter GROUP BY AffId, MonthDate
      5. Compute `CTE_QualifieldMember`:
         - Inner: aggregate per CustId: SELECT AffId, MonthDate, CustId, SUM(ISNULL(Turnover,0) * exchangeRate) AS TurnoverPerCust FROM CTE_DataFilter JOIN TpExchange / Aff_f_ExchangeRate_Sel GROUP BY AffId, MonthDate, CustId
         - Outer: join to `@AffInfo` (for QMTurnover) and COUNT DISTINCT CustId where TurnoverPerCust >= QMTurnover
      6. Aggregate SUM(ActivePlayer) and SUM(QualifiedMember) per AffId and join the results into the dashboard `#Result` (or equivalent temporary result set) as the ActivePlayer and QualifiedRevenueSharePlayers columns.

   - Notes / caveats:
      - Keep the same exchange-rate conversion as the admin SP (`Aff_f_ExchangeRate_Sel`) before comparing to QMTurnover.
      - Preserve the same MemberRemoval exclusion and product-filtering rules to avoid divergence.
      - For multi-month date ranges the reference SP groups by month-bucket then sums per AffId; mirror that behavior if the dashboard needs per-month breakdowns or consistent totals.
      - Add the same clustered index on `#DataMemberDaily` (MonthDate, AffId) to maintain performance parity with the admin SP.

4. CPA path (CPA-only or HYB):
   - Use `MemberCPA` lifecycle fields with schema constraints:
      - Eligible: StatusId = 2; use `HoldingQualifiedDate` for eligibility window.
      - Paid/Settled: StatusId = 3; use `CPADate` for settlement window.
   - Quota handling: fetch `Quota` from `CPAGroupSetting` version overlapping month (open row preferred). RemainingQuota = Quota - SettledCount (if quota null => unlimited).
   - Qualified CPA Player definition (as clarified):
      - Current Month: settled (paid) players are counted only if their `CPADate` falls within the filter range (i.e., `CPADate BETWEEN FromDate AND ToDate`). Eligible players are considered on an "up-to-ToDate" basis — i.e., any `MemberCPA` with `StatusId = 2` and `HoldingQualifiedDate <= ToDate` is a candidate for the remaining quota. The dashboard's QualifiedPlayers (CPA) should therefore be computed as:
          QualifiedPlayers = SettledPlayers_inWindow + MIN(UpToNowRemainingQuota, EligiblePlayers_upToToDate)
         where:
         - SettledPlayers_inWindow = COUNT(*) FROM MemberCPA WHERE StatusId = 3 AND CPADate BETWEEN FromDate AND ToDate
         - EligiblePlayers_upToToDate = COUNT(*) FROM MemberCPA WHERE StatusId = 2 AND HoldingQualifiedDate <= ToDate AND (other filters like AffId apply)
         - UpToNowRemainingQuota = GREATEST(0, Quota - SettledPlayers_inWindow) (if Quota IS NULL treat as unlimited)
      - Past Month: the period is closed — only settled players are counted (QualifiedPlayers = SettledPlayers_inWindow). Eligible players from earlier periods do NOT retroactively qualify that past month.
   - TentativeCPAAmount (visibility rule):
      - Only shown when the web selection's `ToDate` lies inside the current month (i.e., the user is viewing the ongoing month). For this mode calculate tentative CPA payout by summing `MemberCPA.CPAAmount` for eligible candidates ordered by `HoldingQualifiedDate, FirstDepositDate, MemberCPA_ID` and taking the top N rows where N = UpToNowRemainingQuota. The eligible set uses `HoldingQualifiedDate <= ToDate` (up-to-ToDate), while settled CPA amounts are taken from `StatusId = 3` rows with `CPADate BETWEEN FromDate AND ToDate` and included in ApprovedCPAAmount.
   - ApprovedCPAAmount: SUM(CPAAmount) FROM MemberCPA WHERE StatusId = 3 AND CPADate BETWEEN FromDate AND ToDate.

   - Note (clarifying lower-bound): the spec is explicit about the upper-bound (up-to ToDate for eligible players) but does not explicitly state whether eligible players need a minimum HoldingQualifiedDate >= FromDate (i.e., left-bound). Our interpretation: eligible players counted up-to ToDate should ignore the FromDate left-bound and count any eligible rows with HoldingQualifiedDate <= ToDate, because quota consumption is a running up-to-now window in the current month. If you prefer an inclusive-from behavior (HoldingQualifiedDate BETWEEN FromDate AND ToDate) we'll change the rule — please confirm.

5. Clicks: only shown in Month view per spec; use ClickStatistics and archive table with `Aff_f_GetSetting('ArchiveDate_ClickStatistics')`, convert timezones accordingly.

6. Balance Brought Forward: sum `AffTrans` amounts where WinlostDate < ToDate and Status IN (Pending, Approved, Completed) (respect timezone rules in existing SP).

7. Sub-affiliate metrics: `AffInfo` children count by ApprovedDate window; sub-affiliate earning from Commission temp (`SubAffCommission` aggregation) shown only in month view.

## Required DB Actions (high-level)

- ALTER PROCEDURE `Aff_User_Overview_Summary_Sel`:
   - Replace/normalize parameters to use unified `@IsGetMonthly BIT, @FromDate SMALLDATETIME, @ToDate SMALLDATETIME, @BaseCurrency INT` (UI will pass FromDate/ToDate even for monthly mode; when IsGetMonthly=1 SP will normalize to Begin/End of month per rule).
   - Add outputs/columns: GroupTypeName, QualifiedCPAPlayers (new, CPA-specific), TentativeCPAAmount, ApprovedCPAAmount, QualifiedRevenueSharePlayers (keep existing `QualifiedMember` as the RS-qualified count for backward compatibility), SubAffiliateEarning.
   - Note: TentativeRevenueShare and NetRevenue columns for revenue share do NOT require changes as part of this CPA-focused enhancement—leave revenue calculations untouched and continue to rely on `Aff_Commission_Calc`/`Aff_Commission_UnCalc` as appropriate.
   - Implement CPA logic: quota retrieval (`CPAGroupSetting`), candidate selection (`MemberCPA` ordered list), capped sum for tentative CPA, settled sums for approved CPA.
   - Keep RS existing logic and merge hybrid behavior (both CPA + RS shown when necessary).

- No schema DDL changes required immediately; CPI relies on existing columns. If performance issues arise, add recommended indexes: cover `MemberCPA(HoldingQualifiedDate, StatusId, AffId)`, `MemberCPA(CPADate, StatusId, AffId)` and materialize frequent aggregates (rpt tables).

## Dependencies (SPs / functions / jobs)

- `Aff_Commission_Calc` and `Aff_Commission_UnCalc` — used for revenue share metrics.
- `Task_Aff_*` job chain (CPAActivePeriod, CPAHoldingPeriod, CPAApprovalPeriod) — ensure MemberCPA rows are fresh for date windows.
- `Aff_f_ExchangeRate_Sel` — currency conversion for deposit/FTD aggregation.
- `Aff_f_GetSetting` — for ClickStatistics archive boundary.

## Risks / Notes

- Performance: `rptMemberDaily` and `MemberCPA` are high-volume. The SP must keep range scans narrow and use precomputed date variables (WinlostDate, CPADate, HoldingQualifiedDate). Consider adding covering indexes or materialized monthly aggregates if queries degrade.
- Consistency: Tentative (uncalc) values may differ from final calculation due to commission engine changes; document and accept minor drift until final calc runs.
- Quota logic must exactly match ApprovalPeriod logic to avoid mismatches between UI tentative values and actual paid numbers.
- Timezones: unify conversions (GMT+8 primary branch). DepositInfo uses GMT+0 and must be converted when used (existing SP shows patterns).
- Backward compatibility: keep existing output column names unchanged where consumers expect them; append new columns instead of replacing.

## Validation Plan

1. Unit checks (run inside TEST DB):
   - Compare Commission outputs from `Aff_Commission_Calc` / `Aff_Commission_UnCalc` to `Aff_User_Overview_Summary_Sel` for sample affiliate/months.
   - CPA candidate counts: cross-check `MemberCPA` counts and `rptAffiliateCPA` snapshots.
   - Quota enforcement: set small Quota in `CPAGroupSetting` (test-only) and verify TentativeCPAAmount and QualifiedCPAPlayers match capped selection.
   - Click stats: test across archive boundary with `Aff_f_GetSetting('ArchiveDate_ClickStatistics')` toggled.

2. Integration checks (end-to-end):
   - Current month vs past month behavior for RS-only, CPA-only, Hybrid affiliate accounts.
   - Date-range mode hides fields per spec (tentative revenue hidden unless month view; clicks hidden except month view).

3. Acceptance criteria:
   - Solution file reviewed and approved by BA/PM (pair-programming session).
   - All SQL changes only introduced after solution approval; changes must include unit tests or sample run scripts.

## Open Questions / Assumptions

1. UI will pass `@FromDate` for month mode (SP uses it to derive BeginOfMonth); confirm format and that it is never NULL. Current SP used `@MonthDate` — we propose unified interface.
2. Exact mapping of `MemberCPA.StatusId` was derived from `business.md` (2=Eligible, 3=Paid). Confirm with BA/PM if there are environment-specific variants.
3. Which `TransType` values in `AffTrans` represent CPA adjustments/settlements for ApprovedCPAAmount cross-checks? (We used MemberCPA.CPADate and StatusId=3 as primary source.)
4. For quota selection, the ordering tie-breaker is `MemberCPA_ID` after `HoldingQualifiedDate, FirstDepositDate`. Confirm if any other ordering priority is required.
5. Confirm whether Net Revenue formula should use `NetWinloss` from commission temp or recompute using explicit fee columns.

---

If this solution looks good, reply with approval and I will proceed to implement the SQL changes in a follow-up task (phase: coding & tests). If you want changes, please annotate the sections above and I will iterate.
