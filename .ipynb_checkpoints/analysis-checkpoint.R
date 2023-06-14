setwd("/nfs/turbo/umms-bleu-secure/Prechter batch 7/Prechter")

#getwd()
#list.files()

comorb = read.csv('PrechterComorbidities_5dec22.csv', na="NA")
mood = read.csv('Prechter_mood_measures_2dec222.csv', na="NA")
demo = read.csv('Prechter_demographics_2dec22.csv', na="NA")
rx = read.csv('Prechter_RX_2dec22.csv', na="NA")

setwd("/nfs/turbo/umms-bleu-secure/Prechter batch 7/EHR")

#1 for each comorb, 0 if not present
charlson = read.csv('CharlsonComorbidity_5dec22.csv', na="NA")
elix = read.csv('ElixhauserComorbidity_5dec22.csv', na="NA")

medDetails = read.csv('ClarityMedicationDetailedCategorized_2dec22.csv', na="NA")
liver = read.csv('LabsRelatedToLiver_2dec22.csv', na="NA")
medOrder = read.csv('ClarityMedicationOrders_2dec22.csv', na="NA")
medAdminComp = read.csv('MedicationAdministrationsComprehensive_2dec22.csv', na="NA")
diagPSL = read.csv('DiagnosisPSL_5dec22.csv', na="NA")
medOrderComp = read.csv('MedicationOrdersComprehensive_2dec22.csv', na="NA")

install.packages("dplyr")                                      # Install dplyr package
library("dplyr")
library("tidyverse")

#Get only ASRM scores, ignore everything else
moodASRM = mood[mood$variable == 'phq_score',]
uniqueCharlson = unique(charlson)
moodASRM = unique(moodASRM)
uniqueCharlson <- uniqueCharlson %>%
  arrange(record_id, AdmitDate) %>% 
  group_by(record_id) %>% 
  summarise_all(last)
moodASRM <- moodASRM %>%
  arrange(record_id, timestamp) %>% 
  group_by(record_id) %>% 
  summarise_all(last)
moodASRM <- moodASRM %>%
  select('record_id','value')

merged <- inner_join(uniqueCharlson, moodASRM)
mergedFixed <- merged[-c(631),]
mergedFixed$value <- as.double(mergedFixed$value)

mlr.charlson = lm(value ~ AidsHIV + 
                    CerebrovascularDisease + ChronicPulmonaryDisease + 
                    CongestiveHeartFailure + Dementia + 
                    DiabetesWithChronicComplication + DiabetesWithoutChronicComplication + 
                    HemiplegiaParaplegia + Malignancy + 
                    MetastaticSolidTumor + MildLiverDisease + 
                    ModerateSevereLiverDisease + MyocardialInfarction + 
                    PepticUlcerDisease + PeripheralVascularDisease + 
                    RenalDisease + RheumaticDisease, data = mergedFixed)
summary(mlr.charlson)

#unique()
#table()
#%>% rename(record_id = record_id)

