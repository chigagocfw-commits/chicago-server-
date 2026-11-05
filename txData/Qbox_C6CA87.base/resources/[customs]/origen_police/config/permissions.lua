Config.Permissions = {
    [Config.PoliceJobName] = {
        --Tabs
        Dispatch = 1,
        SearchCitizen = 1,
        SearchReports = 1,
        SearchVehicles = 1,
        CriminalCode = 1,
        SearchCapture = 1,
        SearchDebtors = 1,
        FederalManagement = 1,
        AgentManagement = 1,
        SecurityCamera = 1,
        Radio = 1,
        TimeControl = 1,

        -- DISPATCH
        MovePlayerInRadio = 1,
        EnterRadioFreq = 1,
        SendRadioMessage = 1,
        AddNotesToAlert = 1,
        AssignAlertToUnit = 3,

        -- SEARCH CITIZEN
        SetWanted = 1,
        SetDanger = 1,
        CreateNotes = 1,
        PinNotes = 1,
        DeleteNotes = 1,
        CreateBill = 1,
        DeleteBill = 1,
        AddLicenses = 1,
        DeleteLicenses = 1,

        -- REPORTS
        CreateReport = 1,
        AddPeopleToReport = 1,
        AddBillReport = 1,
        RemovePeopleFromReport = 1,
        AddEvidence = 1,
        DeleteEvidence = 1,
        AddReportAgent = 1,
        AddTags = 1,
        RemoveTags = 1,
        AddVictimToReport = 1,
        AddVehicleToReport = 1,
        DeleteReport = 3,

        -- AddFederal
        AddFederal = 1,

        -- SecurityCameras
        SeeBusinessCameras = 3,
        SeeVehicleCamera = 1,
        SeeBodyCams = 1,

        -- PoliceManagement
        GenerateBadge = 1,
        AddPolice = 1,
        ChangePoliceGrade = 1,
        ChangePoliceBadge = 1,
        AddCondecorate = 1,
        RemoveCondecorate = 1,
        AddDivision = 1,
        RemoveDivision = 1,
        HirePolice = 1,

        -- Shapes
        Operations = 1,
        CreateShape = 1,
        DeleteShape = 1,

        -- RIGHT MENU
        RadialCommunicationTab = 1,
        RadioTab = 1,
        InteractTab = 1,
        HolsterTab = 1,
        ObjectPlacementTab = 1,
        CanTackle = 1,
    },
    ["ambulance"] = {
        --Tabs
        Dispatch = 1,
        SearchCitizen = 1,
        SearchReports = 1,
        SearchVehicles = 99,
        CriminalCode = 3,
        SearchCapture = 99,
        SearchDebtors = 99,
        FederalManagement = 99,
        AgentManagement = 3,
        Radio = 1,
        TimeControl = 1,

        -- DISPATCH
        MovePlayerInRadio = 1,
        EnterRadioFreq = 1,
        SendRadioMessage = 1,
        AddNotesToAlert = 1,
        AssignAlertToUnit = 3,

        -- SEARCH CITIZEN
        SetWanted = 1,
        SetDanger = 1,
        CreateNotes = 1,
        PinNotes = 1,
        DeleteNotes = 1,
        CreateBill = 1,
        DeleteBill = 1,
        AddLicenses = 99,
        DeleteLicenses = 99,

        -- REPORTS
        CreateReport = 1,
        AddPeopleToReport = 1,
        AddBillReport = 1,
        RemovePeopleFromReport = 1,
        AddEvidence = 1,
        DeleteEvidence = 1,
        AddReportAgent = 1,
        AddTags = 1,
        RemoveTags = 1,
        AddVictimToReport = 1,
        AddVehicleToReport = 1,
        DeleteReport = 3,

        -- AddFederal
        AddFederal = 99,

        -- SecurityCameras
        SeeBusinessCameras = 99,
        SeeVehicleCamera = 99,
        SeeBodyCams = 3,

        -- PoliceManagement
        GenerateBadge = 99,
        AddPolice = 99,
        ChangePoliceGrade = 99,
        ChangePoliceBadge = 99,
        AddCondecorate = 99,
        RemoveCondecorate = 99,
        AddDivision = 99,
        RemoveDivision = 99,
        HirePolice = 99,

        -- Shapes
        Operations = 99,
        CreateShape = 99,
        DeleteShape = 99,

        -- RIGHT MENU
        RadialCommunicationTab = 1,
        RadioTab = 1,
        InteractTab = 1,
        HolsterTab = 1,
        ObjectPlacementTab = 1,
        CanTackle = 99,
    },
    ["sheriff"] = {
        --Tabs
        Dispatch = 1,
        SearchCitizen = 1,
        SearchReports = 1,
        SearchVehicles = 1,
        CriminalCode = 1,
        SearchCapture = 1,
        SearchDebtors = 1,
        FederalManagement = 1,
        AgentManagement = 1,
        SecurityCamera = 1,
        Radio = 1,
        TimeControl = 1,

        -- DISPATCH
        MovePlayerInRadio = 1,
        EnterRadioFreq = 1,
        SendRadioMessage = 1,
        AddNotesToAlert = 1,
        AssignAlertToUnit = 3,

        -- SEARCH CITIZEN
        SetWanted = 1,
        SetDanger = 1,
        CreateNotes = 1,
        PinNotes = 1,
        DeleteNotes = 1,
        CreateBill = 1,
        DeleteBill = 1,
        AddLicenses = 1,
        DeleteLicenses = 1,

        -- REPORTS
        CreateReport = 1,
        AddPeopleToReport = 1,
        AddBillReport = 1,
        RemovePeopleFromReport = 1,
        AddEvidence = 1,
        DeleteEvidence = 1,
        AddReportAgent = 1,
        AddTags = 1,
        RemoveTags = 1,
        AddVictimToReport = 1,
        AddVehicleToReport = 1,
        DeleteReport = 3,

        -- AddFederal
        AddFederal = 1,

        -- SecurityCameras
        SeeBusinessCameras = 3,
        SeeVehicleCamera = 1,
        SeeBodyCams = 1,

        -- PoliceManagement
        GenerateBadge = 1,
        AddPolice = 1,
        ChangePoliceGrade = 1,
        ChangePoliceBadge = 1,
        AddCondecorate = 1,
        RemoveCondecorate = 1,
        AddDivision = 1,
        RemoveDivision = 1,
        HirePolice = 1,

        -- Shapes
        Operations = 1,
        CreateShape = 1,
        DeleteShape = 1,

        -- RIGHT MENU
        RadialCommunicationTab = 1,
        RadioTab = 1,
        InteractTab = 1,
        HolsterTab = 1,
        ObjectPlacementTab = 1,
        CanTackle = 1,
    },
}

Config.PermissionsGroups = {
    "mod", "admin", "superadmin", "god" -- list of groups that will have all permissions, like "mod", "admin", "superadmin", etc
}

-- DONT TOUCH ANYTHING BELOW THIS LINE
exports("GerPermissions", function()
    return Config.Permissions
end)

if not Config.JobCategory[Config.PoliceJobCategory] then
    print("Looks like you have a wrong police job category setted in the Config.PoliceJobCategory option, please check the config/permissions.lua file")
end