setwd("/nfs/turbo/umms-bleu-secure/Prechter batch 7/Prechter")

#getwd()
#list.files()

comorb = read.csv('PrechterComorbidities_5dec22.csv', na="NA")
mood = read.csv('Prechter_mood_measures_2dec222.csv', na="NA")
demo = read.csv('Prechter_demographics_2dec22.csv', na="NA")
#rx = read.csv('Prechter_RX_2dec22.csv', na="NA")

setwd("/nfs/turbo/umms-bleu-secure/Prechter batch 7/EHR")

#1 for each comorb, 0 if not present
charlson = read.csv('CharlsonComorbidity_5dec22.csv', na="NA")
#elix = read.csv('ElixhauserComorbidity_5dec22.csv', na="NA")

#medDetails = read.csv('ClarityMedicationDetailedCategorized_2dec22.csv', na="NA")
liver = read.csv('LabsRelatedToLiver_2dec22.csv', na="NA")
#medOrder = read.csv('ClarityMedicationOrders_2dec22.csv', na="NA")
#medAdminComp = read.csv('MedicationAdministrationsComprehensive_2dec22.csv', na="NA")
diagPSL = read.csv('DiagnosisPSL_5dec22.csv', na="NA")
#medOrderComp = read.csv('MedicationOrdersComprehensive_2dec22.csv', na="NA")

install.packages("dplyr")                                      # Install dplyr package
library("dplyr")
library("tidyverse")

#comorb %>% count(value, sort = TRUE) %>% top_n(20)

#Select necessary columns and filter out desired values
charlsonData <- subset(charlson, select = -c(TotalScore, DischargeDate))
comorbData = comorb[comorb$variable == "be_dsmiv",]
comorbData = comorbData[,c("record_id", "timestamp", "measure_age", "value")]
demoData = demo[,c("record_id", "timestamp", "measure_age", "gender", "baseline_schoolyear_complete", "baseline_marital_status")]
diagPSLData = diagPSL[diagPSL$ProblemDescription %in% c("Hyperlipidemia", "Anxiety", "Hypertension", "Obesity"),]
diagPSLData = diagPSLData[,c("record_id", "ProblemObservationDate", "ProblemDescription")]
liverData = liver[liver$RESULT_NAME == "ALBUMIN LEVEL",]
liverData = liverData[,c("record_id", "COLLECTION_DATE", "VALUE")]


moodData = mood[mood$variable == 'phq_score',]
moodData = moodData[,c("record_id", "timestamp", "measure_age", "value")]


#Format date
charlsonData$AdmitDate <- sub(" .*", "", charlsonData$AdmitDate)

#Get most recent date by ID
#length(unique(comorbData$record_id))
charlsonData <- charlsonData %>% group_by(record_id) %>% top_n(1, as.Date(AdmitDate))
charlsonData <- unique(charlsonData)
comorbData <- comorbData %>% group_by(record_id) %>% top_n(1, as.Date(timestamp, format="%m-%d-%y"))
comorbData <- unique(comorbData)
demoData <- demoData %>% group_by(record_id) %>% top_n(1, as.Date(timestamp))
demoData <- unique(demoData)
diagPSLData <- diagPSLData %>% group_by(record_id) %>% top_n(1, as.Date(ProblemObservationDate))
diagPSLData <- unique(diagPSLData)
liverData <- liverData %>% group_by(record_id) %>% top_n(1, as.Date(COLLECTION_DATE))
liverData <- liverData %>% group_by(record_id) %>% top_n(1, VALUE)
liverData <- unique(liverData)
moodData <- moodData %>% group_by(record_id) %>% top_n(1, as.Date(timestamp))
moodData <- moodData %>% group_by(record_id) %>% top_n(1, value)
moodData <- unique(moodData)

#Remove dates and age
charlsonData <- subset(charlsonData, select = -c(AdmitDate))
comorbData <- subset(comorbData, select = -c(timestamp, measure_age))
demoData <- subset(demoData, select = -c(timestamp))#Keep age here
diagPSLData <- subset(diagPSLData, select = -c(ProblemObservationDate))
liverData <- subset(liverData, select = -c(COLLECTION_DATE))
moodData <- subset(moodData, select = -c(timestamp, measure_age))


#change categorical variable to binary
comorbData$value <- comorbData$value != "Healthy/Control (V71.09)" #healthy = 0
comorbData <- unique(comorbData)
comorbData$value <- as.integer(as.logical(comorbData$value))
colnames(comorbData)[2] ="mental_ilness"
demoData$gender <- demoData$gender == "Male" #Male = 1
demoData$divorced <- demoData$baseline_marital_status == "Divorced"
demoData$hasMarried <- demoData$baseline_marital_status != "Never Married"
demoData <- subset(demoData, select = -c(baseline_marital_status))
demoData$gender <- as.integer(as.logical(demoData$gender))
demoData$divorced <- as.integer(as.logical(demoData$divorced))
demoData$hasMarried <- as.integer(as.logical(demoData$hasMarried))
diagPSLData$obesity <- diagPSLData$ProblemDescription == "Obesity"
diagPSLData$hypertension <- diagPSLData$ProblemDescription == "Hypertension"
diagPSLData$anxiety <- diagPSLData$ProblemDescription == "Anxiety"
diagPSLData$hyperlipidemia <- diagPSLData$ProblemDescription == "Hyperlipidemia"
diagPSLData <- subset(diagPSLData, select = -c(ProblemDescription))
diagPSLData$obesity <- as.integer(as.logical(diagPSLData$obesity))
diagPSLData$hypertension <- as.integer(as.logical(diagPSLData$hypertension))
diagPSLData$anxiety <- as.integer(as.logical(diagPSLData$anxiety))
diagPSLData$hyperlipidemia <- as.integer(as.logical(diagPSLData$hyperlipidemia))
colnames(liverData)[2] ="liver_function"
colnames(moodData)[2] ="mood"
moodData <- moodData[!is.na(as.numeric(moodData$mood)), ]#Delete NA responses
#Merge
colnames(charlsonData)[1] ="record_id"
final <-charlsonData %>% inner_join(comorbData)
final <-final %>% inner_join(demoData)
#final2 <- final %>% left_join(diagPSLData)
final <-final %>% inner_join(moodData)
final <- subset(final, select = -c(baseline_schoolyear_complete))#Too many NAs
final$mood <- as.double(final$mood)
final$mood <- as.integer(final$mood)





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

