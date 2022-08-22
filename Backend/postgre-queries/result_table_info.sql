SELECT split_part(pr."resultTableSpecific", '_', 1) AS assay_id,
       split_part(pr."resultTableSpecific", '_', 2) AS tissue_id,
       split_part(pr."resultTableSpecific", '_', 3) AS cell_type_id,
       pr."parameter",
       pr."intercept",
       pr."meanUMI"
FROM public."priorsResult" pr LIMIT 6 OFFSET 6*0