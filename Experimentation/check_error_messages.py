import re

text = """
"completeDatasetID" "idToName" "errorMessage" "datasetBodySpecific" "cellCount"
"EFO:0011025_UBERON:0000178_CL:0000897" "10x 5' v1_blood_CD4-positive, alpha-beta memory T cell" "Error in parametricDispersionFit_DEseq(means, disps): Parametric dispersion fit failed.
" "1_1_26" 3276


"completeDatasetID" "idToName" "errorMessage" "datasetBodySpecific" "cellCount"
"EFO:0011025_UBERON:0000178_CL:0000816" "10x 5' v1_blood_immature B cell" "Error in parametricDispersionFit_DEseq(means, disps): Parametric dispersion fit failed.
" "1_1_26" 255


"completeDatasetID" "idToName" "errorMessage" "datasetBodySpecific" "cellCount"
"EFO:0011025_UBERON:0000178_CL:0000775" "10x 5' v1_blood_neutrophil" "Error in parametricDispersionFit_DEseq(means, disps): Parametric dispersion fit failed.
" "1_1_26" 299
"""

# Regular expression pattern to find the error message between double quotes
pattern = r'"(Error in .+?)"'

# Search for the pattern in the text
matches = re.findall(pattern, text, re.DOTALL)

# Print the error messages
#for match in matches:
    #print(match)

# unique error messages
unique_errors = list(set(matches))

for error in unique_errors:
    print(error)