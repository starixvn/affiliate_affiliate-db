# CPA Calculation Stored Procedures (Part 1)

This section documents the CPA lifecycle job stored procedures. Each entry includes: Purpose, Parameters, Core Steps, Data Writes, Idempotency / Re-run Behavior, and Failure Modes.

| SP Name | Purpose | Phase | Main Tables Written |
|---------|---------|-------|---------------------|
| Task_Aff_CPACalculation_Job | Orchestrates sequential execution of CPA sub-steps for a day | Wrapper | CPAJobLog (+ delegates) |
| Task_Aff_CPAResetIsAbnormal | Resets previously marked abnormal players back to Pending if tags no longer abnormal | Pre-Active | MemberCPA |
| Task_Aff_CPAActivePeriod | Qualifies players for Active period (creates / updates MemberCPA, Tier & Product details, archives EOL) | Active | MemberCPA, MemberCPATier, MemberCPAProduct, MemberCPA_EOL |
| Task_Aff_CPAHoldingPeriod | Evaluates Holding bet ticket condition and updates status / holding dates | Holding | MemberCPA |
| Task_Aff_CPAMarkIsAbnormal | Marks players as abnormal (StatusId=4) based on tag rules | Post-Holding (filter) | MemberCPA |
| Task_Aff_CPACheckRedeposit | Checks redeposit condition inside monitoring window, sets IsRedeposit flag | Monitoring | MemberCPA |
| Task_Aff_CPAPaymentSchedule | Builds per-affiliate schedule row (rptAffiliateCPA) from qualified holding completions | Payment Prep | rptAffiliateCPA |
| Task_Aff_CPAApprovalPeriod | Creates AffTrans (financial) and sets StatusId=3 (Paid); applies quota rules | Approval | AffTrans, MemberCPA |
| Task_Aff_UpdateDealSchedule | Advances NextBillingDate of deals of given Type | Post-Approval | DealBillingSchedule |

## StatusId Legend (MemberCPA)


0 Pending / Active Phase in progress
1 Active Completed (Holding pending or failed)
2 Eligible (Holding met & awaiting payment window / redeposit)
3 Settled / Paid
4 Abnormal (excluded)
5 Quota Exceeded (not paid)
6 Redeposit Failed (post monitoring)

---

## 1. Task_Aff_CPACalculation_Job


Wrapper job SP. Accepts @Step and @Date. If @Date NULL, uses yesterday (GMT+8). Executes sub-SPs conditionally by @Step value (0 runs all). Logs each step into CPAJobLog with timing and basic error message. Truncates CPAJobLog history to last 2000 rows.

Parameters: @Step INT, @Date DATE
Writes: CPAJobLog rows; cascaded writes inside called procedures.
Failure: RAISERROR on any sub-step non-zero @ErrCode.
Re-run: Safe; individual steps use deterministic daily filters.

## 2. Task_Aff_CPAResetIsAbnormal


Resets StatusId=4 records back to 0 (Pending) if their current TagList no longer contains any abnormal tags and registration date within relevant rolling window derived from ActiveDays + HoldingDays.

Parameters: @CPADate DATE
Logic Highlights:
List:

* Validates date.
* Joins MemberCPA -> MemberInfo -> CPAGroupSetting (current ToDate=9999-12-31)
* Excludes rows still carrying abnormal tags via NOT EXISTS on bodb_12B.dbo.Tag.IsAbnormal.
Writes: MemberCPA.StatusId, Description cleared, UpdatedDate set GMT+8.
Failure: @ErrCode=100 if date null.
Re-run: Idempotent (only affects StatusId=4 without abnormal tags).

## 3. Task_Aff_CPAActivePeriod


Most complex phase. Determines qualified Active period players, handles recalculation and new players separately, assigns tiers, products, totals, and archives expired non-qualified players.

Parameters: @CPADate DATE, @ErrCode OUTPUT, @ErrMsg OUTPUT
Key Temp Tables:
Temp tables:

* #GroupCountry / #GroupCurrency: Derive currency-country mappings per group.
* #DealSetting: Active CPATierSetting per group/product with MaxTier.
* #PlayerDeal: Player baseline (existing & new pass). Contains deadlines, previous ActiveQualifiedDate.
* #PlayerProductSummary: Aggregated deposit/turnover/bets per product (old and current period passes).
* #PlayerProductQualification: Matched tiers with CPAAmount.

Core Steps (existing players first, then new):
Steps:

1. Resolve base currency & settings.
2. Build group → currency mapping and deal tier settings.
3. Load existing MemberCPA players for potential recalculation (OldActiveQDate included).
4. Summarize old Active period turnover, deposits, FDM.
5. Tier matching: filter by MinFDM, MinTotalDeposit, MinTO; choose highest TierId via delete-lower rows.
6. Delete obsolete MemberCPA (+ cascades to tiers/products) when no longer qualifying, group changed, or target country removed.
7. MERGE upsert into MemberCPA (Pending status 0) updating totals & ActiveQualifiedDate.
8. Archive expired players (MemberCPA_EOL) when deadlines exceeded without qualification.
9. Rebuild MemberCPATier and MemberCPAProduct detail rows (delete then reinsert).
10. Repeat similar process for truly new players (second block) with current Active window.
Writes: MemberCPA, MemberCPATier, MemberCPAProduct, MemberCPA_EOL; Deletes invalid rows.
Failure: sets @ErrCode / @ErrMsg; early null date check.
Re-run: Recalculation supported; deletes & reinserts detail ensures consistency.
Performance: Multiple clustered/nonclustered indexes on temp tables; exchange rate applied via Aff_f_ExchangeRate_Sel per row.

## 4. Task_Aff_CPAHoldingPeriod


Evaluates Holding phase bet tickets for members in StatusId=0 after Active qualification.

Parameters: @CPADate DATE, @ErrCode OUTPUT, @ErrMsg OUTPUT
Temp Tables:
Temp tables:

* #Member: Candidate members with ActiveQualifiedDate, old/new holding windows, deadlines.
* #BetTickets: Aggregated bet counts with logic for old qualification date vs CPADate+1.
Logic:

1. Load members in status 0 within registration window.
2. Aggregate bet tickets into three categories: already qualified by old range, qualified by CPADate range, not eligible yet.
3. Update #Member with HoldingBetTickets, HoldingQualifiedDate, StatusID (2 if met, 1 if deadline passed w/out meeting, 2 if holding skipped by 0 tickets requirement).
4. Persist changes to MemberCPA: HoldingQualifiedDate, HoldingBetTickets, HoldingExpiredDate, StatusId.
Writes: MemberCPA rows updated.
Failure: Null date validation only.
Re-run: Idempotent; recalculates counts but StatusId transitions stabilized by deadlines.

## 5. Task_Aff_CPAMarkIsAbnormal


Marks members as abnormal (StatusId=4) if TagList contains any tag with IsAbnormal=1 for their registration window (Active+Holding day offset).

Parameters: @CPADate DATE
Logic:
List:

* Validates date.
* Uses STRING_SPLIT on TagList to aggregate abnormal tags into Description.
* Updates StatusId to 4 if not previously 3/4; sets UpdatedDate.
Writes: MemberCPA.StatusId=4, Description populated, UpdatedDate.
Re-run: Idempotent (re-mark stays 4), description rebuilt from current tags.

## 6. Task_Aff_CPACheckRedeposit


During monitoring window after holding qualification (StatusId=2), checks if cumulative deposits (excluding first deposit baseline FDM) exceed initial FDM requirement before ExpiredRedepositDate.

Parameters: @CPADate DATE, @ErrCode OUTPUT, @ErrMsg OUTPUT
Temp Tables: #MembersToCheck (with FDM), #RedepositResults.
Logic:
Steps:

1. Load members with StatusId=2, IsRedeposit=0, CPADate in monitoring range.
2. Update FDM from MemberInfo converted via exchange rate.
3. Sum deposits from rptMemberDaily between FirstDepositDate and min(@CPADate, ExpiredRedepositDate).
4. Flag IsRedeposit=1 if cumulative > FDM.
Writes: MemberCPA.IsRedeposit, UpdatedDate.
Failure: Null date check.
Re-run: Only sets flag when condition met; safe.

## 7. Task_Aff_CPAPaymentSchedule


Generates per-affiliate per-group schedule entries (rptAffiliateCPA) for payment monitoring & approval; also updates prior 'Monitoring' rows with current redeposit progress.

Parameters: @CPADate DATE, @ErrCode OUTPUT, @ErrMsg OUTPUT
Temp Tables:
Temp tables:

* #EligibleGroupsWithAff: Billing cycle group-affiliate pairs.
* #QualifiedMembers: Newly eligible members holding-qualified in cycle.
* #OldMonitoringGroups / #UpdatedMonitoringSchedule: Prior cycles still monitoring.
* #NewCPASchedule: Current cycle results (including groups with zero members).
Logic:

1. Load eligible group-aff pairs whose NextBillingDate = @CPADate.
2. Collect qualified members (StatusId=2) within cycle window.
3. Recompute old monitoring row metrics & statuses (Monitoring, Qualified, Not Qualified, Empty).
4. Build new schedule rows including quota of required redeposits (floor(count * rate)).
5. Update existing monitoring rows; insert new rows.
Status Rules Summary:

* Empty: No qualified players.
* Monitoring: Some qualified, redeposit threshold unmet, still in window.
* Qualified: Either no redeposit requirement or threshold met.
* Not Qualified: Redeosit window expired without meeting threshold.
Writes: Updates & inserts in rptAffiliateCPA.
Re-run: Safe; recalculates aggregates; duplicates avoided by distinct cycle boundaries.

## 8. Task_Aff_CPAApprovalPeriod

Final payout & status transition. Applies quota limits, creates AffTrans transactions, updates MemberCPA StatusId=3 (Paid). Sub-CPA calculation section commented (future extension).

Parameters: @CPADate DATE, @ErrCode OUTPUT, @ErrMsg OUTPUT
Temp Tables:
Temp tables:

* #EligibleGroups, #QualifiedMembers, #QuotaStatus, #MemberCPABackup, #MainPayouts.
Logic:

1. Validate parameters & load system settings.
2. Identify groups with billing date and their quota & schedule.
3. Collect StatusId=2 members; compute quota consumption (PaidCount vs Quota).
4. Mark excess beyond quota as StatusId=5 (Quota exceeded) by ROW_NUMBER ordering.
5. Create AffTrans rows for each affiliate aggregated CPAAmount.
6. Update MemberCPA: StatusId=3, RefId=TransId, CPADate set, UpdatedDate timezone adjusted.
7. CATCH block restores MemberCPA from backup and deletes generated transactions if failure occurs.
Writes: AffTrans, MemberCPA updates (status, RefId, CPADate).
Failure: Sets @ErrCode and message; rollback logic for main payouts.
Re-run: Safe; already paid members (StatusId=3) not reprocessed; quota mark stable.

## 9. Task_Aff_UpdateDealSchedule

Advances NextBillingDate for schedules of provided @Type on the executed @Date based on Schedule.IntervalType & IntervalValue (months offset uses EOMONTH + 4 days rule).

Parameters: @Date DATE, @Type VARCHAR(100)
Writes: DealBillingSchedule.NextBillingDate.
Failure: Null date check; updates may skip if no schedules match.
Re-run: Not idempotent; should only run once per cycle per @Date.

---

Next Step: Confirm this section before documenting Deal Setting SPs.

## Deal Setting Stored Procedures (Part 2)

Administrative Deal management: create, update, delete, list, and fetch metadata (types, schedules, target countries). This section standardizes each Deal SP with Purpose, Parameters, Validation Rules, Core Steps, Data Writes, Concurrency / Idempotency, and Error Codes.

| SP Name | Purpose | Category | Main Tables Written |
|---------|---------|----------|---------------------|
| Aff_Admin_Deal_GroupType_Sel | List enabled deal group types for dropdown | Lookup | (none) |
| Aff_Admin_Deal_Schedule_Sel | List available schedules for deal billing | Lookup | (none) |
| Aff_Admin_Deal_PlayerTargetCountry_ListSel | List target countries joined to exchange codes | Lookup | (none) |
| Aff_Admin_Deal_Sel | Paged search of deals with affiliate count | Listing | (none temp only) |
| Aff_Admin_Deal_Detail_Sel | Full detail of one deal (Revenue + CPA tiers + deductions + products) | Detail | (none) |
| Aff_Admin_Deal_Ins | Create a new Revenue / CPA / Hybrid deal (with versioned CPA settings) | Mutation | CommGroup, CommGroupHistory, TierSetting(+History), DeductionSetting(+History), CPAGroupSetting, CPATierSetting, CPAProductSetting, DealBillingSchedule, Log |
| Aff_Admin_Deal_Upd | Update existing deal; versioning new CPA rows if changed; replaces revenue/deduction tiers | Mutation | CommGroup, CommGroupHistory, TierSetting(+History), DeductionSetting(+History), CPAGroupSetting, CPATierSetting, CPAProductSetting, Log |
| Aff_Admin_Deal_Del | Soft delete a deal (IsDeleted=1) with JSON snapshot logging | Mutation | CommGroup (IsDeleted), Log |
| Aff_Admin_Assign_Deal | Assign a deal (commission group) to an affiliate with history versioning + logging | Operation | AffInfo, AffGroupHistory, CommGroup |
| Aff_Admin_Assign_Deal_Sel | Dropdown of commission groups and current affiliate group | Operation Lookup | (none) |

## Shared Concepts

* Deal Types: 1 Revenue Share, 3 CPA, 4 Hybrid.
* Versioning (CPA only): Rows have FromDate / ToDate with open-ended ToDate = 9999-12-31. Updates either (a) same-day replacement (delete & reinsert) or (b) close previous ToDate to yesterday and insert a new open row.
* Infinity Constants: MinAmount negative infinity = -100000000000; MaxAmount positive infinity = 100000000000; MaxQM = 1000000000; CPA max caps use 100000000000.
* Logging JSON sections: di (Deal Info), ci (CPA Info), ct (CPA Tiers), ri (Revenue Info), rt (Revenue Tiers). Insert writes @NewData only; Update writes both @OldData & @NewData; Delete logs @OldData.
* Permission: All mutation SPs call Aff_Con_CheckPermission with @FuncName='[Deal]'; abort on @ErrCode <> 0.
* Timezone Normalization: @CurrentDate = DATEADD(HOUR,12,GETDATE()) then CAST(@CurrentDate AS DATE) for action date windows.

## Error Code Map (Observed)

| ErrCode | Meaning (context) |
|---------|--------------------|
| 100 | Group does not exist (update path) |
| 101 | Invalid / empty group (deal) name |
| 102 | Deal name already exists / cannot create duplicate |
| 103 | Tier count exceeds 50 (Revenue or CPA tiers) |
| 105 | Insert failed (SCOPE_IDENTITY() null) |
| 106 | Sub-commission rate invalid when required |
| 201 | First tier Min Net Win must be 0 or -∞ |
| 202 | Next tier after negative tier must start at 1 |
| 203 | Min Net Win values must increase sequentially |
| 302 | Missing / invalid CPA Tier list XML |
| 303 | CPA product list missing required fields |
| 304 | Duplicate ProductId in CPA product list |
| 309 | Generic CPA tier/product validation (multiple distinct checks) |
| 311 | Target country list required |
| 312 | ActiveDays must be > 0 |
| 313 | HoldingDays & HoldingTickets must both be set if either > 0 |
| 314 | Quota cannot be negative |
| 315 | RedepositDays and RedepositRate must both be set if either > 0 |
| 316 | StartDate must be >= today |

## A. Aff_Admin_Deal_GroupType_Sel

Purpose: Returns enabled group types for UI dropdown.

Parameters: (none)

Core Steps:

* Select GroupTypeId, GroupTypeBy, GroupTypeName WHERE IsEnabled=1.

Writes: None.
Concurrency: Read-only with NOLOCK.
Idempotency: Always same result unless underlying table changes.
Errors: None explicit.

## B. Aff_Admin_Deal_Schedule_Sel

Purpose: Returns schedule list (ScheduleId, ScheduleName) for assigning to deals.

Parameters: (none)

Core Steps:

* Select from Schedule ordered by ScheduleID.

Writes: None.
Concurrency: Read-only.
Idempotency: Stable.

## C. Aff_Admin_Deal_PlayerTargetCountry_ListSel

Purpose: Provides combined exchange and target country codes for deal CPA target selection.

Parameters: (none)

Core Steps:

* Join Exchange to TargetCountry on CountryCode; DISTINCT projection.

Writes: None.
Concurrency: Read-only.
Idempotency: Stable; relies on static reference tables.

## D. Aff_Admin_Deal_Sel

Purpose: Paged listing & filtering of deals with affiliate count and metadata.

Parameters:

* @GroupId INT = 0 (optional exact filter)

## I. Aff_Admin_Assign_Deal

Purpose: Change affiliate's commission group (deal) and version affiliate group history; produce structured JSON log containing old/new deal name, type, and action date.

Parameters:

* @UserId INT (permission check via Aff_Con_CheckPermission '[Deal]')
* @AffId INT (target affiliate)
* @GroupId INT (new commission group)
* @ErrCode / @ErrMsg OUTPUT

Core Steps:

1. Permission validation.
2. Validate new GroupId existence & not deleted (Err 100 on missing).
3. Read current affiliate GroupId; if unchanged → early return.
4. Determine MonthDate (end-of-month) & action date (GMT+8 normalized to midday + 12 hours).
5. If same-day reassign attempt exists: delete prior same-day open row.
6. Close previous open AffGroupHistory row (set ToDate = ActionDate -1) if any.
7. Insert new AffGroupHistory open-ended row (ToDate = 9999-12-31).
8. Build JSON: Old (previous group + original FromDate) and New (new group + action date) wrapped under "da".
9. Write log via Aff_UserLog_RunSP_Detail_WriteLog.

Writes: AffInfo.GroupId, AffGroupHistory (delete/update/insert), UserLog.
Idempotency: Re-running with same @GroupId no-op (returns early).
Concurrency: Uses ROWLOCK, UPDLOCK on update/closing operations; limited contention per affiliate.
Errors: 100 (Group not existed); permission errors via Aff_Con_CheckPermission (@ErrCode propagated).

## J. Aff_Admin_Assign_Deal_Sel

Purpose: Provide dropdown list of active deals filtered by optional GroupType plus current affiliate's deal.

Parameters:

* @AffID INT (optional) populates @GroupID OUTPUT with current group.
* @GroupTypeId INT filter (0=all).

Logic: If @AffID provided, fetch its GroupID; list CommGroup (IsDeleted=0 and (GroupTypeId=@GroupTypeId OR @GroupTypeId=0)).
Writes: None.
Idempotency: Pure read.
Performance: Simple index usage on CommGroup.GroupTypeId + IsDeleted.
* @GroupName NVARCHAR(100) (partial LIKE)
* @GroupTypeId INT = 0
* @PageIndex INT (1-based)
* @PageSize INT
* @NRows OUTPUT total row count

Temp Objects: #Deals (RowNum, GroupId, DealName, DealType, NoAff, Description, UpdatedBy, UpdatedDate).

Core Steps:

1. Filter CommGroup (IsDeleted=0) join GroupType.
2. OUTER APPLY COUNT affiliates (AffInfo by GroupId).
3. Row-number ordering by ISNULL(UpdatedTime, CreatedDate) DESC.
4. Persist into #Deals then output total rows via @NRows.
5. Page boundaries computed (RowStart/RowEnd) and returned.

Writes: Temp table only.
Concurrency: Read-only; NOLOCK usage; paging unaffected by concurrent inserts except possible phantom rows.
Idempotency: Listing; deterministic per snapshot.
Errors: None explicit; misuse of page values could lead to empty results.

## E. Aff_Admin_Deal_Detail_Sel

Purpose: Retrieve full detail of a single deal including Revenue tiers & deductions and CPA tiers & products.

Parameters: @GroupId INT

Result Sets (multiple):

1. Deal header (GroupName, GroupTypeId, Description, SubCommRate, IsSubCommRate, Revenue & CPA fields, ScheduleId, IsActivePlayerSum).
2. Revenue Tier list (TierSetting ordered by GroupProductId,TierId).
3. Revenue Deduction list (DeductionSetting grouped with aggregated ProductIds via XML + STUFF technique, excluding related products from Aff_f_GroupProduct()).
4. CPA Tier list (CPATierSetting ToDate=9999-12-31).
5. CPA Product mapping (CPAProductSetting aggregated distinct ProductIds by GroupProductId).

Writes: None.
Concurrency: Read-only.
Idempotency: Stable snapshot; uses NOLOCK (possible dirty reads).
Errors: None explicit (missing @GroupId returns empty sets).

## F. Aff_Admin_Deal_Ins

Purpose: Create a new deal (Revenue, CPA, or Hybrid) with validation, derived tier ranges, CPA version rows, billing schedule initialization, and audit logging.

Parameters (selected):

* @UserId INT (permission check)
* @GroupId INT OUTPUT (assigned SCOPE_IDENTITY)
* @GroupName NVARCHAR(100)
* @GroupTypeId INT (1,3,4)
* Revenue: @QMTurnover MONEY, @IsActivePlayerSum BIT, @DeductionList XML, @TierList XML
* CPA: @CountryCodes VARCHAR(MAX), @ActiveDays SMALLINT, @HoldingDays SMALLINT, @HoldingTickets SMALLINT, @Quota SMALLINT, @RedepositDays SMALLINT, @RedepositRate DECIMAL(9,8), @StartDate DATE, @ScheduleId SMALLINT, @CPATierList XML, @CPAProductList XML
* @SubCommRate DECIMAL(9,8), @IsSubCommRate BIT
* Logging: @IP VARCHAR(50), @ErrCode OUTPUT, @ErrMsg OUTPUT

Validation Highlights:

* Name present / unique (Err 101/102).
* Sub-commission required if @IsSubCommRate=1 (Err 106).
* Revenue tiers: build @TierSetting, auto MaxAmount chaining; enforce first tier 0/-∞ (201), negative tier next start=1 (202), sequential increments (203), tier count <=50 (103).
* CPA tiers: presence (302), each group/tier unique & tiers <=50 (103/309), at least one condition among MinFDM, MinTotalDeposit, MinTO (309), min values ascending per tier (309), CPAAmount >=0 (309), product list required if any MinTO present (309), product list uniqueness & completeness (303,304,309), quota & country non-empty & positive validations (311,312,313,314,315,316).

Core Steps:

1. Permission check.
2. Parse @DeductionList into @DeductionSetting (expands related products) if Revenue/Hybrid.
3. Parse @TierList into @TierSetting; derive GroupProductId via deductions; compute MaxAmount boundaries.
4. Parse CPA tiers/products similarly; compute MaxFDM/MaxTotalDeposit/MaxTO chaining & finalize last tier caps.
5. Insert CommGroup (conditional columns by type) & obtain @GroupId.
6. Insert CommGroupHistory snapshot for current month.
7. Insert Revenue tier + history & deductions + history (if applicable).
8. Insert CPAGroupSetting / CPATierSetting / CPAProductSetting (version rows FromDate=ActionDate, ToDate=∞) plus DealBillingSchedule with next billing computed (MONTH uses EOMONTH(StartDate, IntervalValue-1)+4 days, otherwise StartDate + IntervalValue -1 days).
9. Build JSON for logging (di, ri, rt, ci, ct) and write via Aff_UserLog_RunSP_Detail_WriteLog.

Writes: CommGroup, CommGroupHistory, TierSetting, TierSettingHistory, DeductionSetting, DeductionSettingHistory, CPAGroupSetting, CPATierSetting, CPAProductSetting, DealBillingSchedule, Log table.
Concurrency: Minimal contention (single-row inserts + small table writes); ROWLOCK/UPDLOCK not used on inserts; SCOPE_IDENTITY ensures atomic retrieval.
Idempotency: Not idempotent (re-running creates duplicate deal with same name unless validation blocks).
Errors: Comprehensive via @ErrCode mapping; early RETURN on validation failure.

## G. Aff_Admin_Deal_Upd

Purpose: Update an existing deal; rewrites revenue tiers/deductions; versions CPA settings with date-range logic; logs old vs new JSON snapshots.

Parameters: Similar to insert except @GroupId (input) and no @ScheduleId for CPA changes (pulled from existing CommGroup) unless altering? (ScheduleId re-used from current record). Includes @CPATierList/@CPAProductList for CPA changes.

Validation: Same as insert (qualifies existing group, unique name constraints excluding self, tier & CPA validations). Reuses error codes (100 group missing, 101/102 name issues, plus all tier/CPA codes).

Core Steps:

1. Permission & existence checks.
2. Load group type & current CPA schedule data.
3. Parse/validate revenue & CPA XML blocks into table variables.
4. Update CommGroup with consolidated CASE field logic.
5. Capture deleted OLD revenue settings into #updateData for logging.
6. Delete & reinsert TierSetting / DeductionSetting (+ History) for month (ensures current snapshot idempotency).
7. CPA versioning logic:

	* Compare changed fields; if same-day update (FromDate=ActionDate) delete open rows then insert new open rows.
	* Else close existing ToDate to yesterday and insert new open rows.

8. Repeat for CPATierSetting (add/remove/change detection via FULL OUTER JOIN), and CPAProductSetting (add/remove detection).
9. Build Old & New JSON fragments for every section (di, ci, ct, ri, rt) using prior captured data sets.
10. Write log with @OldData and @NewData.

Writes: CommGroup (UpdatedTime/by), CommGroupHistory (month snapshot), TierSetting(+History), DeductionSetting(+History), CPAGroupSetting, CPATierSetting, CPAProductSetting, Log.
Concurrency: Uses ROWLOCK, UPDLOCK for updates; versioning avoids overlapping date ranges; same-day replacement prevents invalid FromDate=ToDate gaps.
Idempotency: Safe if repeated with identical parameters (no changes -> versioning blocks skip). Changes produce new version rows only once per action date.
Errors: Same codes; returns early on validation failure.

## H. Aff_Admin_Deal_Del

Purpose: Soft delete a deal (IsDeleted=1) after ensuring no affiliate currently assigned; logs pre-delete snapshot.

Parameters: @UserId, @GroupId, @IP, @ErrCode OUTPUT, @ErrMsg OUTPUT.

Validation:

* Permission check.
* Existence of GroupId (Err 101 reused with message id 1006 in code path).
* Ensure no AffInfo row references GroupId (Err 102 with message id 1008).

Core Steps:

1. Permission & existence & usage checks.
2. Read CommGroup type to branch building JSON.
3. Construct JSON: di (deal info), ri/rt (Revenue details if type 1/4), ci/ct (CPA details if type 3/4) by querying multiple tables with NOLOCK.
4. Update CommGroup.IsDeleted=1 (ROWLOCK, UPDLOCK).
5. Write log with @OldData only.

Writes: CommGroup (IsDeleted), Log entry.
Concurrency: Single row update; safe under locking hints.
Idempotency: Second invocation finds group IsDeleted=1 (not explicitly handled but would pass initial exists check and mark again—log may differ if data changed externally).
Errors: 101/102 as above.

## Concurrency & Locking Summary

* Lookup & listing SPs use NOLOCK (potential dirty / phantom reads acceptable for UI dropdowns).
* Mutations apply ROWLOCK + UPDLOCK only when updating existing rows; inserts rely on default locking.
* Versioning ensures no overlapping CPA effective ranges: previous open rows are either deleted (same-day) or ToDate adjusted to previous day before new row insert.

## Idempotency & Re-run Behavior

| SP | Idempotent? | Notes |
|----|-------------|-------|
| GroupType_Sel | Yes | Pure read. |
| Schedule_Sel | Yes | Pure read. |
| PlayerTargetCountry_ListSel | Yes | Pure read. |
| Deal_Sel | Yes | Snapshot paging. |
| Deal_Detail_Sel | Yes | Multiple result sets, no side effects. |
| Deal_Ins | No | Creates new deal; duplicate prevented by name uniqueness. |
| Deal_Upd | Conditional | Only writes if differences detected; repeat same params yields no new CPA version rows. |
| Deal_Del | Mostly | Second run logs again; IsDeleted already set. |
| Assign_Deal | Conditional | No-op if same GroupId; otherwise history versioning + log. |
| Assign_Deal_Sel | Yes | Pure read dropdown. |

## Logging Structure Notes

* Insert: Only @NewData JSON recorded.
* Update: Both @OldData and @NewData (diff friendly).
* Delete: Only @OldData preserved.
* JSON keys abbreviate domain terms: dn (DealName), dt (DealType text), sr (SubCommRate), qpt (Quarterly? Actually QMTurnover), cqp (IsActivePlayerSum), fd/td/w (MinFDM, MinTotalDeposit, MinTO), cpa (CPAAmount), rpg/cpg (Revenue/CPA product groups), rf (Revenue factor deduction pct), rti/cti (tier arrays), ap/hd/ht/q/rd/rr etc.

---

Next Step: Review Part 2 formatting, then proceed to Assignment & Reporting SPs (Part 3) upon confirmation.

## Assignment & Reporting Stored Procedures (Part 3)

This section covers: Deal assignment, statement history, CPA payment & player-level CPA reports, affiliate aggregate reports (summary + detail), player activity breakdown, and CPA payment adjustments.

| SP Name | Purpose | Category | Main Tables Read | Main Tables Written |
|---------|---------|----------|------------------|---------------------|
| Aff_Admin_StatementHistory_Sel | Monthly statement (earnings, payments, adjustments, CPA tentative & approved) with pagination | Reporting (Financial History) | AffTrans, CommGroup, MemberCPA, AffGroupInfo (function), SystemSettings | Temp (#tempData), output only |
| Aff_Admin_Report_PaymentCPA | Per payment schedule CPA status + amounts (estimate/approved/adjusted) with filtering & paging | Reporting (CPA Payment) | rptAffiliateCPA, AffInfo, CommGroup, Schedule | Temp (#data) |
| Aff_Admin_PaymentCPA_Adjustment_Ins | Insert CPA adjustment transaction and update schedule row | Payment Adjustment | rptAffiliateCPA, AffInfo, SystemSettings | AffTrans, rptAffiliateCPA, UserLog |
| Aff_Admin_Report_PlayerCPA | Player-level CPA lifecycle view with status & phase indicators | Reporting (Player CPA) | MemberCPA, MemberInfo, AffInfo, CommGroup, Schedule | Temp (#data) |
| Aff_Admin_Report_PlayerCPA_TO_Detail | Break down CPA tier turnover by group product and product | Reporting (CPA Detail) | MemberCPATier, MemberCPAProduct, Products | Temp (#data) |
| Aff_Admin_AffiliateReport_Sel | Affiliate aggregate metrics (multi-month) with hybrid calc (historical vs recent) + sorting/paging | Reporting (Affiliate Summary) | rptMemberDaily, DepositInfo, MemberInfo, AffTrans, ClickStatistics(+_bk), CommGroup, SystemSettings | Temp (#TempCommission, #Result, others) |
| Aff_Admin_AffiliateReport_Detail_Sel | Single affiliate month-by-month detailed metrics (hybrid deposit approach) | Reporting (Affiliate Detail) | rptMemberDaily, DepositInfo, MemberInfo, AffTrans, ClickStatistics(+_bk), SystemSettings, Schedule, CommGroup | Temp tables (#TempCommission, #IP, #Statistics, etc.) |
| Aff_Admin_PlayersDetail_Sel | Per-player aggregated activity metrics with hybrid deposit logic & currency conversion | Reporting (Player Activity) | rptMemberDaily, DepositInfo, MemberInfo, DeductionSettingHistory, AffGroupHistory, SystemSettings | Temp (#tmpData, #DataByMonth, #tmpDeductionSettings) |

### Shared Reporting Patterns

* Hybrid Data Split: Historical (<= AFF_CommissionDate) uses rptMemberDaily; Recent (> boundary) uses DepositInfo for deposits / counts. Pre-computed commission boundary = AFF_CommissionDate + 1 day.
* Currency Normalization: CROSS APPLY Aff_f_ExchangeRate_Sel(date, sourceExchangeId, @BaseExchangeId) applied at aggregation boundaries.
* Timezone Adjustments: Click statistics convert between GMT+8 (app logic) and GMT-4 storage; deposit CreateTime from GMT+0 adjusted to GMT+8.
* Paging: Row-number window specification with dynamic ORDER BY based on @SortType / @IsSortAsc / @SortDirectionType.
* Temp Tables: All heavy reporting SPs rely on temp (# or table variables) for intermediate aggregation; lifetime ends inside procedure (no side effects outside transactions / adjustments SP).

---

### 1. Aff_Admin_StatementHistory_Sel

Purpose: Monthly financial statement slice for affiliate including: revenue share (calculated/uncalculated/tentative), sub-aff share, CPA (tentative / approved / adjustments), payments (withdrawals) and admin adjustments. Supports dynamic date range & pagination.

Parameters Highlights: @AffId, @FDate/@TDate (nullable; defaults to min report date → today), paging (@PageSize,@PageIndex), @NRows OUTPUT.

Core Components:

* Aff_f_GetMinReportDate to bound earliest month.
* Aff_f_AffGroupInfo_Sel returns group type per month (determines inclusion of CPA vs revenue items).
* Temp (#tempData) holds unified transaction rows with CalculatedType flags (0 current, 1 uncalculated future, 2 calculated past). Temp (#tempData_CPA) for CPA-specific transaction classification.
* Commission Split: Historical months (<= AFF_CommissionDate) aggregated from AffTrans of types (201 revenue, 204 sub-aff, 206 CPA settlement, 208 CPA adjustment, 209 tentative). Future/un-calculated months built via Aff_Commission_UnCalc for revenue share projection.
* CPA Tentative: Quota-aware logic enumerating eligible (StatusId=2) players up to remaining quota (or all if unlimited) for current month.
* Payment / Adjustment: AffTrans types 202 (payment out), 203 (adjustment in) converted to positive/absolute where needed.
* Pagination: DENSE_RANK ordered by MonthDate DESC then transaction precedence.

Outputs:

* Paged set of unified statement rows.
* @NRows total count (excluding sub-aff row type 204 in count logic).

Writes: Temp tables only.
Idempotency: Yes (no persistent writes).
Errors: Early returns on invalid date ordering.
Performance Notes: Multi-phase inserts; beware of AFF_CommissionDate boundary for invoking Aff_Commission_UnCalc (costly) only when necessary.

### 2. Aff_Admin_Report_PaymentCPA

Purpose: Payment schedule level CPA monitoring & approval summary, with multi-filter on affiliate username, deal list, status set, date view mode (EndSchedule / ApprovedDate / AdjustedDate), paging & totals.

Parameters Highlights: @UserName, @DealIds (CSV), @Status (CSV), @Viewby (1/2/3), @FromDate/@ToDate (filter chosen date field), paging & export flags.

Core Steps:

1. Parse lists into table variables (@Deals, @Statuses).
2. Load schedule rows from rptAffiliateCPA joined to AffInfo, CommGroup, Schedule applying dynamic date filter based on @Viewby.
3. Compute derived fields: TotalRequiredRedepositPlayers = FLOOR(TotalEligiblePlayers * RedepositRate); FinalCPAAmount = COALESCE(AdjustedAmount, ApprovedAmount, 0); IsEnabled gating logic (60-day window, manual approval state).
4. Populate temp #data; assign row number (Rid) for paging.
5. Return paged result with enumerated StatusId mapping and aggregated totals (EligiblePlayers, amounts).

Writes: Temp only.
Idempotency: Yes.
Errors: None explicit (empty results possible if filters mismatch).
Performance: Filtering using EXISTS on small table variables; potential benefit adding indexes to rptAffiliateCPA on EndSchedule, ApprovedDate, AdjustedDate for date-mode queries.

### 3. Aff_Admin_PaymentCPA_Adjustment_Ins

Purpose: Apply manual CPA adjustment to a payment schedule; insert AffTrans record and update rptAffiliateCPA with adjusted amount/date & description + logging.

Parameters Highlights: @AffID, @PaymentID (rptAffiliateCPA.ID), @NewAmount (final), @AdjustAmount (transaction delta), @Transdesc description, @UserID, outputs @ErrCode/@ErrMsg.

Validation & Errors:

* Permission check '[Payment]' (generic error codes propagate).
* Affiliate existence (Err 102), Affiliate approved status (Err 103).
* Payment schedule existence & status (must be Qualified/Not Qualified) (Err 105).
* TRY/CATCH wraps insert/update (Err 104 on failure).

Core Steps:

1. Gather timezone & computed WinlostDate (adjusted by 4 + TimeZone hours) and exchange rate for affiliate currency → base (AffRate).
2. Validate affiliate & status; retrieve schedule Start/End dates.
3. Insert AffTrans (TransType=208 Adjustment CPA) with Amount=@AdjustAmount.
4. Update rptAffiliateCPA (AdjustedAmount, AdjustedDate, Description, AdjustedBy, UpdatedDate).
5. Build log string (simple key=value) and record via Aff_UserLog_RunSP_Detail_WriteLog (NewData only).

Writes: AffTrans, rptAffiliateCPA, UserLog.
Idempotency: Non-idempotent (re-running adds another transaction and overwrites schedule AdjustedAmount). Guard by UI disable (should not repeat inadvertently).
Performance: Single row inserts/updates; minimal.

### 4. Aff_Admin_Report_PlayerCPA

Purpose: Player-level CPA lifecycle report with Active/Holding/Redeposit markers, status mapping, abnormal flag, and estimated vs settled CPA amounts.

Parameters: @UserName (affiliate), @CustName (player), @DealName CSV list of GroupIds, @StatusId CSV of StatusIds, @Viewby (1 ActiveQualifiedDate, 2 HoldingQualifiedDate), date range.

Core Steps:

1. Parse filters into @Deals & @Status tables.
2. Select MemberCPA joined to MemberInfo, AffInfo, CommGroup, Schedule with filter on chosen phase date (ActiveQualifiedDate or HoldingQualifiedDate between @FromDate/@ToDate).
3. Derive booleans: IsFTD (FDM>0), IsTotalDeposit (TotalDeposit>0), IsTO (Turnover>0), IsHolding presence of HoldingBetTickets, EstimatedCPAAmount if status in eligible/paid states.
4. Map StatusId into CPAStatus text; build abnormal flag (StatusId=4).
5. Summaries: total CPAAmount & EstimatedCPAAmount.

Writes: Temp table #data only.
Idempotency: Yes.
Performance: Straight select with grouping only for final sums; ensure indexes on MemberCPA (ActiveQualifiedDate, HoldingQualifiedDate, StatusId, GroupId, AffId).

### 5. Aff_Admin_Report_PlayerCPA_TO_Detail

Purpose: Expand a single player's CPA tier record into group product and per-product turnover & CPA distribution.

Parameters: @MemberCPAID INT.

Core Steps:

1. Aggregate MemberCPATier rows by GroupProductId (Turnover, CPAAmount) into #data.
2. Return group product summary rows.
3. Join MemberCPAProduct for per-product turnover (no CPAAmount at product granularity) with product names.
4. Return grand totals.

Writes: Temp table.
Idempotency: Yes.
Performance: Single MemberCPA_ID filter; relies on indexes (MemberCPATier.MemberCPA_ID, MemberCPAProduct.MemberCPA_ID).

### 6. Aff_Admin_AffiliateReport_Sel

Purpose: Multi-affiliate summary across period with sorting on numerous KPI axes (clicks, signup, FDM, turnover, earnings, qualified members, etc.). Handles hybrid historical/recent deposit & FDM calculation and multi-currency conversions.

Parameters: Extensive filtering: @Username, @GroupIds CSV, date range, product list, statuses (Approved/Suspended), language, payment currency, flags to exclude negative BBF values, monthly vs exact date mode (@IsGetMonthly), paging, sort types (1-9).

Core Steps (Monthly mode):

1. Build month list (@MonthDate) using recursive CTE.
2. Split commission months by AFF_CommissionDate into calculated (Aff_Commission_Calc) and uncalculated (Aff_Commission_UnCalc) inserts into #TempCommission (all affiliates or 'all').
3. Statistics: Clicks & unique IPs from ClickStatistics vs ClickStatistics_bk with archived boundary & timezone shift.
4. Signup & FDM: Combined CTEs for signup, FDM_Amount, and hybrid FDM_TotalDeposit (historical rptMemberDaily vs recent DepositInfo) into #Signup.
5. Withdrawal/Adjustments & running balance (BFF / CurrentBBF) aggregated from AffTrans (types 202/203 + all amounts).
6. TotalDeposit & TotalWithdrawal (hybrid approach) combining DepositInfo & rptMemberDaily into #TotalDeposit.
7. Merge all into #Result with row numbers ordered by dynamic sort selection.
8. Optional filters: exclude marketing/test accounts depending on flags.
9. Return paged rows + totals row.

Non-monthly mode path builds direct daily aggregates via rptMemberDaily and custom logic (branch inside procedure when @IsGetMonthly=0).

Writes: Temp tables (#TempCommission, #Result, #Signup, #AffTrans, #Statistics, #TotalDeposit).
Idempotency: Yes.
Performance: Heavy. Index reliance on rptMemberDaily (WinlostDate, AffId), DepositInfo (WinlostDate, CreateTime), ClickStatistics (UpdatedTime, AffId). Potential improvements: precomputed materialized views for large periods.

### 7. Aff_Admin_AffiliateReport_Detail_Sel

Purpose: Month-by-month details for a single affiliate with identical hybrid logic to summary SP but deeper per-month decomposition, adding active/qualified players, FDM_TotalDeposit, fees, sub-aff counts and running BFF.

Parameters: @Username (affiliate), month range or full, products, currencies, base currency, sorting, export flag.

Core Steps:

1. Normalize date boundaries and month recursion (CTE_MonthDate) generating row count (@NRows).
2. Hybrid commission calculation splitting by MaxCommDate (Aff_Commission_Calc vs Aff_Commission_UnCalc).
3. Build #TempCommission for both calculated and uncalculated periods.
4. Gather click statistics (active & archived tables) with IP uniqueness rules (IsExcluded=0 filter).
5. Signup + FDM hybrid (FirstDepositAmount / TotalDeposit split by boundary) with exchange rate conversion.
6. Sub-affiliate counts (Approved, within date range).
7. Deposit/Withdrawal hybrid (DepositInfo + rptMemberDaily) aggregated with currency conversion.
8. Affiliate transactions (withdrawal/adjustment, BFF running accumulation) into @tblAffStatistics.
9. MemberStatistics combining Signup, FDM, FDM_Amount, FDM_TotalDeposit.
10. Compose final row set with dynamic sorting and dual output: detail rows (paged) + totals row.

Writes: Multiple temp tables only.
Idempotency: Yes.
Performance: Similar considerations as summary; per-affiliate reduces data volume.

### 8. Aff_Admin_PlayersDetail_Sel

Purpose: Player activity breakdown for an affiliate across date range with per-player aggregated finances and fee calculations, supporting currency filters, product filters, removal status inclusion, sorting, and hybrid deposit logic.

Parameters: @AffId, date range, @ProductId filter (expands related products), @Currencies, @BaseCurrency, sorting id (1–14), @IsIncludeRemovedPlayer, paging/export.

Key Mappings:

* SortById: enumerates Username, RegisteredDate, Deposit, Withdrawal, Turnover, GGR, Bonus, Rebate, DepositFee, WithdrawalFee, IBCUserName, FirstDepositDate, FirstDepositAmount, DepositCount.
* Deduction Settings (deposit & withdrawal fees) per month derived from DeductionSettingHistory (IDs 13/14) joined via AffGroupHistory.
* Hybrid deposit & deposit count: historical via rptMemberDaily (<= boundary), recent via DepositInfo (> boundary) with timezone conversion.

Core Steps:

1. Build month list for fee lookup.
2. Populate #tmpDeductionSettings converting currencies.
3. Aggregate rptMemberDaily per month & player (includes negative Winloss adjustments for GGR). Exclude removed players unless flag.
4. If range beyond commission boundary, add recent deposits & counts from DepositInfo (per CustId).
5. Summarize monthly data (#DataByMonth) → CTE_SumData → join fee settings and exchange rate to produce #tmpData with final amounts and computed DepositFee / WithdrawalFee.
6. Remove zero activity players.
7. Sort and page results, returning base fields plus flags.
8. Output IsCPADealOnly flag (aff group history inspection for group type detection).

Writes: Temp tables only.
Idempotency: Yes.
Performance: Aggregations per player; advisable indexes on rptMemberDaily (AffId, WinlostDate, ProductId, CustId), DepositInfo (CustId, WinlostDate, CreateTime, Status) to maintain responsiveness.

---

### Error & Idempotency Summary

| SP | Custom @ErrCode Usage | Destructive Writes | Idempotent? |
|----|-----------------------|--------------------|-------------|
| Aff_Admin_StatementHistory_Sel | None (early returns) | No | Yes |
| Aff_Admin_Report_PaymentCPA | None | No | Yes |
| Aff_Admin_PaymentCPA_Adjustment_Ins | 102,103,105,104 | Inserts AffTrans & updates rptAffiliateCPA | No |
| Aff_Admin_Report_PlayerCPA | None | No | Yes |
| Aff_Admin_Report_PlayerCPA_TO_Detail | None | No | Yes |
| Aff_Admin_AffiliateReport_Sel | None | No | Yes |
| Aff_Admin_AffiliateReport_Detail_Sel | None | No | Yes |
| Aff_Admin_PlayersDetail_Sel | None | No | Yes |

### Performance Considerations (Reporting SPs)

* Heavy use of UNION/UNION ALL between historical vs recent partitions; ensure statistics up to date on large tables (rptMemberDaily, DepositInfo, ClickStatistics).
* String splitting for CSV filters: consider inline TVFs or pre-sanitized lists for high-frequency calls.
* Exchange rate CROSS APPLY executed per grouped row—batching by month to reduce function calls already employed; avoid per-detail row invocation where possible.
* Fee calculation multiplication applied post aggregation to minimize row volume.

---

Next Step: Confirm Part 3; optionally proceed with Part 4 (Additional Payment / Adjustment utilities or further CPA analytics) if required.


