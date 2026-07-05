WITH stg AS (
    -- The ref function tells dbt this depends on stg_loans
    -- dbt automatically builds stg_loans before this model
    SELECT * FROM {{ ref('stg_loans') }}
),

cleaned AS (
    SELECT
        -- -- Pass through unchanged ----------------------------
        loan_id, loan_amnt, funded_amnt, term, int_rate,
        installment, grade, sub_grade, purpose, home_ownership,
        verification_status, loan_status, dti, open_acc, pub_rec,
        revol_bal, revol_util, total_acc, delinq_2yrs, inq_last_6mths,
        tot_cur_bal, total_rev_hi_lim, acc_open_past_24mths, avg_cur_bal,
        bc_open_to_buy, bc_util, mort_acc, num_actv_bc_tl, num_bc_sats,
        num_il_tl, num_op_rev_tl, num_rev_accts, num_sats, pct_tl_nvr_dlq,
        percent_bc_gt_75, pub_rec_bankruptcies, tax_liens, tot_hi_cred_lim,
        total_bal_ex_mort, total_bc_limit, issue_d,

        -- -- Null imputation -----------------------------------
        -- Null = borrower has no delinquency/record history
        -- 999 preserves this signal better than mean imputation
        -- tells the model this happened a very long time ago or never
        COALESCE(mths_since_last_delinq, 999)       AS mths_since_last_delinq,
        COALESCE(mths_since_last_record, 999)        AS mths_since_last_record,
        COALESCE(mths_since_last_major_derog, 999)   AS mths_since_last_major_derog,

        -- -- FICO score ----------------------------------------
        -- Average the low/high band to get a single representative score
        (fico_range_low + fico_range_high) / 2.0    AS fico_score,

        -- -- Employment length ---------------------------------
        -- Convert string categories to ordinal numeric values
        CASE
            WHEN emp_length = '10+ years' THEN 10
            WHEN emp_length = '9 years'   THEN 9
            WHEN emp_length = '8 years'   THEN 8
            WHEN emp_length = '7 years'   THEN 7
            WHEN emp_length = '6 years'   THEN 6
            WHEN emp_length = '5 years'   THEN 5
            WHEN emp_length = '4 years'   THEN 4
            WHEN emp_length = '3 years'   THEN 3
            WHEN emp_length = '2 years'   THEN 2
            WHEN emp_length = '1 year'    THEN 1
            WHEN emp_length = '< 1 year'  THEN 0
            ELSE NULL   -- 'n/a' becomes NULL
        END                                         AS emp_length_years,

        -- -- Log income ----------------------------------------
        -- Reduces right skew from high earners
        -- +1 before log to safely handle any zero values
        LN(annual_inc + 1)                          AS log_annual_inc,

        -- -- Credit age ----------------------------------------
        -- earliest_cr_line format: 'Jan-2000'
        -- Subtract year from 2015 (midpoint of training data)
        -- Longer credit history = generally lower default risk
        CASE
            WHEN earliest_cr_line IS NULL THEN NULL
            ELSE 2015 - CAST(
                SUBSTR(earliest_cr_line, LENGTH(earliest_cr_line) - 3, 4)
                AS INTEGER)
        END                                         AS credit_age_years

    FROM stg
)

SELECT * FROM cleaned