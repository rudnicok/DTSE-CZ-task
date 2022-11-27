--- Point to parts that could be optimized
--- Feel free to comment any row that you think could be optimize/adjusted in some way!
--- The following query is from SAP HANA but applies to any DB
--- Do not worry if the tables/columns are not familiar to you 
----   -> you do not need to interpret the result (in fact the query does not reflect actual DB content)
SELECT 
	RSEG.EBELN,
	RSEG.EBELP,
    RSEG.BELNR,
    RSEG.AUGBL AS AUGBL_W,
    LPAD(EKPO.BSART,6,0) as BSART,
	BKPF.GJAHR,
	BSEG.BUKRS,
	BSEG.BUZEI,
	BSEG.BSCHL,
	BSEG.SHKZG,
    CASE WHEN BSEG.SHKZG = 'H' THEN (-1) * BSEG.DMBTR ELSE BSEG.DMBTR END AS DMBTR,
    COALESCE(BSEG.AUFNR, 'Kein SM-A Zuordnung') AS AUFNR,
    COALESCE(LFA1.LAND1, 'Andere') AS LAND1, 
    LFA1.LIFNR,
    LFA1.ZSYSNAME,
    BKPF.BLART as BLART,
    BKPF.BUDAT as BUDAT,
    BKPF.CPUDT as CPUDT
FROM "DTAG_DEV_CSBI_CELONIS_DATA"."dtag.dev.csbi.celonis.data.elog::V_RSEG" AS RSEG
--All JOINS have 1=1 condition, I haven't used it before and suppose there is no impact on performance.
--Depends on the goal of merging it can be replaced by CROSS JOIN. If it's Inner Join, there is no need in 1=1
LEFT JOIN "DTAG_DEV_CSBI_CELONIS_WORK"."dtag.dev.csbi.celonis.app.p2p_elog::__P2P_REF_CASES" AS EKPO ON 1=1
    AND RSEG.ZSYSNAME = EKPO.SOURCE_SYSTEM
    AND RSEG.MANDT = EKPO.MANDT
-- I'd separate operations concatenation and merging to speed up processing
    AND RSEG.EBELN || RSEG.EBELP = EKPO.EBELN || EKPO.EBELP 
--For INNER JOIN BKPF, BSEG and LFA1 I would write expressions/calculations/filtration before joining to reduce the size of dataset 
-- with SELECT WHERE like in the last JOIN and temporary table
INNER JOIN "DTAG_DEV_CSBI_CELONIS_DATA"."dtag.dev.csbi.celonis.data.elog::V_BKPF" AS BKPF ON 1=1
    AND BKPF.AWKEY = RSEG.AWKEY
    AND RSEG.ZSYSNAME = BKPF.ZSYSNAME
--Don't see the reason to use IN with one value, can be replaced by =
    AND RSEG.MANDT in ('200')
INNER JOIN "DTAG_DEV_CSBI_CELONIS_DATA"."dtag.dev.csbi.celonis.data.elog::V_BSEG" AS BSEG ON 1=1
    AND DATS_IS_VALID(BSEG.ZFBDT) = 1
    AND BSEG.KOART = 'K'
    AND CAST(BSEG.GJAHR AS INT) = 2020
    AND BKPF.ZSYSNAME = BSEG.ZSYSNAME
    AND BKPF.MANDT = BSEG.MANDT
    AND BKPF.BUKRS = BSEG.BUKRS
    AND BKPF.GJAHR = BSEG.GJAHR
    AND BKPF.BELNR = BSEG.BELNR
    AND BSEG.DMBTR*-1 >= 0
--We use just 4 columns from the table LFA1, so they can be selected instead of selecting all columns. 
--Last operation can be in brackets for TEMP
INNER JOIN (SELECT * FROM "DTAG_DEV_CSBI_CELONIS_DATA"."dtag.dev.csbi.celonis.data.elog::V_LFA1" AS TEMP
            WHERE TEMP.LIFNR > '020000000') AS LFA1 ON 1=1 
    AND BSEG.ZSYSNAME = LFA1.ZSYSNAME
    AND BSEG.LIFNR=LFA1.LIFNR
    AND BSEG.MANDT=LFA1.MANDT
    AND LFA1.LAND1 in ('DE','SK')
;