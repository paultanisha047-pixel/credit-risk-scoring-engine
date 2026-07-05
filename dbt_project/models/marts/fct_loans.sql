
-- 1. Creates binary target (default_flag): 1=defaulted, 0=repaid
-- 2. Ordinal encodes grade A=1 to G=7
-- 3. Ordinal encodes sub_grade A1=1 to G5=35
-- 4. Creates chronological train/test split flag (is_train)
--    Loans before 2016 = training set
--    Loans from 2016 onwards = test set
--    Time-based split prevents temporal leakage — the model never
--    trains on loans it would have to predict in production
-- 5. Selects final 50 features for ML training

WITH int AS (
    SELECT * FROM {{ ref('int_loans_cleaned') }}
),

final AS (
    SELECT
        -- ── Identifiers ───────────────────────────────────────
        loan_id,

        -- ── Target variable ───────────────────────────────────
        -- 1 = defaulted (Charged Off)
        -- 0 = repaid (Fully Paid)
        CASE
            WHEN loan_status = 'Charged Off' THEN 1
            WHEN loan_status = 'Fully Paid'  THEN 0
        END                                         AS default_flag,

        -- ── Train/test split ──────────────────────────────────
        -- issue_d format: 'Jan-2015' — extract last 4 chars = year
        -- true  = training set (before 2016)
        -- false = test set (2016 onwards)
        CASE
            WHEN CAST(
                SUBSTR(issue_d, LENGTH(issue_d) - 3, 4)
                AS INTEGER) < 2016
            THEN true
            ELSE false
        END                                         AS is_train,

        -- ── Loan characteristics ──────────────────────────────
        loan_amnt,
        funded_amnt,
        term,
        int_rate,
        installment,

        -- ── Grade encoding ────────────────────────────────────
        -- Ordinal — A is best credit quality, G is worst
        CASE grade
            WHEN 'A' THEN 1 WHEN 'B' THEN 2 WHEN 'C' THEN 3
            WHEN 'D' THEN 4 WHEN 'E' THEN 5 WHEN 'F' THEN 6
            WHEN 'G' THEN 7
        END                                         AS grade_encoded,

        -- ── Sub-grade encoding ────────────────────────────────
        -- 35 sub-grades from A1=1 (best) to G5=35 (worst)
        CASE sub_grade
            WHEN 'A1' THEN 1  WHEN 'A2' THEN 2  WHEN 'A3' THEN 3
            WHEN 'A4' THEN 4  WHEN 'A5' THEN 5  WHEN 'B1' THEN 6
            WHEN 'B2' THEN 7  WHEN 'B3' THEN 8  WHEN 'B4' THEN 9
            WHEN 'B5' THEN 10 WHEN 'C1' THEN 11 WHEN 'C2' THEN 12
            WHEN 'C3' THEN 13 WHEN 'C4' THEN 14 WHEN 'C5' THEN 15
            WHEN 'D1' THEN 16 WHEN 'D2' THEN 17 WHEN 'D3' THEN 18
            WHEN 'D4' THEN 19 WHEN 'D5' THEN 20 WHEN 'E1' THEN 21
            WHEN 'E2' THEN 22 WHEN 'E3' THEN 23 WHEN 'E4' THEN 24
            WHEN 'E5' THEN 25 WHEN 'F1' THEN 26 WHEN 'F2' THEN 27
            WHEN 'F3' THEN 28 WHEN 'F4' THEN 29 WHEN 'F5' THEN 30
            WHEN 'G1' THEN 31 WHEN 'G2' THEN 32 WHEN 'G3' THEN 33
            WHEN 'G4' THEN 34 WHEN 'G5' THEN 35
        END                                         AS sub_grade_encoded,

        -- ── Borrower financials ───────────────────────────────
        log_annual_inc,
        dti,
        emp_length_years,
        home_ownership,
        verification_status,
        purpose,

        -- ── Credit history ────────────────────────────────────
        fico_score,
        credit_age_years,
        delinq_2yrs,
        inq_last_6mths,
        mths_since_last_delinq,
        mths_since_last_record,
        mths_since_last_major_derog,
        open_acc,
        pub_rec,
        revol_bal,
        revol_util,
        total_acc,

        -- ── Credit bureau detail ──────────────────────────────
        tot_cur_bal,
        total_rev_hi_lim,
        acc_open_past_24mths,
        avg_cur_bal,
        bc_open_to_buy,
        bc_util,
        mort_acc,
        num_actv_bc_tl,
        num_bc_sats,
        num_il_tl,
        num_op_rev_tl,
        num_rev_accts,
        num_sats,
        pct_tl_nvr_dlq,
        percent_bc_gt_75,
        pub_rec_bankruptcies,
        tax_liens,
        tot_hi_cred_lim,
        total_bal_ex_mort,
        total_bc_limit

    FROM int
    -- Drop any rows where target is ambiguous
    WHERE default_flag IS NOT NULL
)

SELECT * FROM final
 ⁠

---