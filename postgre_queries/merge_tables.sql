WITH connection_tuple AS (
    SELECT CAST(split_part(pr."datasetBodySpecific", '_', 1) AS INTEGER) AS cell_count,
           CAST(split_part(pr."datasetBodySpecific", '_', 2) AS INTEGER) AS assay_length,
           CAST(split_part(pr."datasetBodySpecific", '_', 3) AS INTEGER) AS tissue_length,
           CAST(split_part(pr."datasetBodySpecific", '_', 4) AS INTEGER) AS cell_type_length
    FROM public."priorsResult" pr
)

SELECT * 
FROM public."todos" td
WHERE td."CellCount" = (SELECT cell_count FROM connection_tuple LIMIT 1)
AND   json_array_length(td."Assay") = (SELECT assay_length FROM connection_tuple LIMIT 1)
AND   json_array_length(td."Tissue") = (SELECT tissue_length FROM connection_tuple LIMIT 1)
AND   json_array_length(td."CellType") = (SELECT cell_type_length FROM connection_tuple LIMIT 1)