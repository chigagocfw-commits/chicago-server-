local defaultJob = "police"

-- Translation overrides for different jobs (e.g., EMS/ambulance)
local translationOverrides = {}

translationOverrides.ambulance = {
  Report = "ReportEms",
  Reports = "ReportsEms",
  Fine = "ReportBillsEms",
  AddFine = "AddReportBillEms",
  ReportName = "ReportNameEms",
  ReportID = "ReportIdEms",
  ReportDescription = "ReportDescEms",
  Evidences = "ReportEvidencesEms",
  AddEvidence = "AddReportEvidenceEms",
  PeopleInvolved = "ReportPeopleEms",
  AddPeople = "ReportAddPeopleEms",
  AgentsInvolved = "ReportAgentsEms",
  AddAgent = "ReportAddAgentEms",
  ReportList = "ReportListEms",
  SearchReport = "SearchReportEms",
  NewReport = "NewReportEms",
  SelectReport = "SelectReportEms",
  AgentInCharge = "AgentInChargeEms",
  EnterReportDesc = "EnterReportDescEms",
  DestroyReport = "DestroyReportEms"
}

-- Generate default translations for the default job
function GenerateDefaultTranslations()
  for jobName, overrides in pairs(translationOverrides) do
    translationOverrides[defaultJob] = {}
    
    for key, value in pairs(translationOverrides[jobName]) do
      translationOverrides[defaultJob][key] = key
    end
    break
  end
end

local originalTranslations = {}
local currentJob = defaultJob

-- Apply translation overrides based on job
function ApplyTranslationsOverride(jobName)
  -- Use default job if no job or no overrides exist
  if not jobName or not translationOverrides[jobName] then
    jobName = defaultJob
  end
  
  -- Skip if already on this job
  if currentJob == jobName then
    return
  end
  
  currentJob = jobName
  
  -- Apply translation overrides
  for key, value in pairs(translationOverrides[jobName]) do
    if key == value then
      -- Restore original translation
      Translations[key] = originalTranslations[key] or Translations[key]
      originalTranslations[key] = nil
    else
      -- Save original and apply override
      originalTranslations[key] = Translations[key]
      Translations[key] = Translations[value]
    end
  end
  
  -- Update UI with new translations
  SendNUIMessage({
    action = "UpdateTranslations",
    translations = Translations
  })
end

-- Handle job updates
RegisterNetEvent("origen_police:client:OnJobUpdate", function(jobData)
  if not jobData or not jobData.name then
    return
  end
  
  ApplyTranslationsOverride(jobData.name)
end)

-- Handle player loaded
RegisterNetEvent("origen_police:client:OnPlayerLoaded", function()
  local playerData = FW_GetPlayerData()
  
  if playerData and playerData.job and playerData.job.name then
    ApplyTranslationsOverride(playerData.job.name)
  end
end)

-- Initialize default translations
GenerateDefaultTranslations()