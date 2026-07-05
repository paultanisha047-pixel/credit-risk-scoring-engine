WITH source AS (
    -- Pull from raw_loans table in DuckDB
    -- The source function tells dbt this is an external table, not a dbt model
    SELECT * FROM {{ source('raw', 'raw_loans') }}
),

filtered AS (
    -- Keep only loans with known final outcomes
    -- Fully Paid = repaid = label 0
    -- Charged Off = defaulted = label 1
    -- Current, Late, In Grace Period excluded — outcome still unknown
    SELECT * FROM source
    WHERE loan_status IN ('Fully Paid', 'Charged Off')
),

renamed AS (
    SELECT
        -- -- Loan characteristics ------------------------------
        id                                                                  AS loan_id,
        loan_amnt,
        funded_amnt,

        -- term comes as ' 36 months' — strip to integer
        CAST(REPLACE(REPLACE(term, ' months', ''), ' ', '')
            AS INTEGER)                                                     AS term,

        -- Already numeric in DuckDB - safe pass-through
        CAST(int_rate AS FLOAT)                                             AS int_rate,

        installment,
        grade,
        sub_grade,
        purpose,
        home_ownership,
        verification_status,
        loan_status,

        -- -- Borrower financials -------------------------------
        annual_inc,
        COALESCE(dti, 0.0)                                                  AS dti,
        -- emp_length kept as string here — converted in int_loans_cleaned
        emp_length,

        -- -- Credit history at origination ---------------------
        fico_range_low,
        fico_range_high,
        earliest_cr_line,
        open_acc,
        pub_rec,
        revol_bal,

        -- Already numeric in DuckDB - safe pass-through
        CAST(revol_util AS FLOAT)                                           AS revol_util,

        total_acc,
        delinq_2yrs,
        inq_last_6mths,
        mths_since_last_delinq,
        mths_since_last_record,

        -- -- Credit bureau detail ------------------------------
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
        total_bc_limit,
        mths_since_last_major_derog,

        -- -- Date for train/test split -------------------------
        -- Used in fct_loans to create chronological split flag
        issue_d

    FROM filtered
)

SELECT * FROM renamed