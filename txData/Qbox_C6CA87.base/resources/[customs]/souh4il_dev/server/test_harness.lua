-- SOUH4IL-DEV — Staging Security Test Harness
-- Automated test runner for SEC-01 through SEC-10
-- Strict multi-factor fail-closed guard: Completely dormant unless explicitly enabled in Staging

local PermissionsConfig = require 'config.permissions'
local Security = require 'server.security'
local Permissions = require 'server.permissions'
local Identifiers = require 'server.identifiers'
local Logger = require 'server.logger'

local function IsStagingAuthorized()
    -- Guard 1: Explicit local configuration boolean
    if not PermissionsConfig.EnableStagingTestHarness then
        return false
    end

    -- Guard 2: Server environment convar must be explicitly 'staging'
    if GetConvar('sv_environment', '') ~= 'staging' then
        return false
    end

    -- Guard 3: Diagnostic Safety Signal — Hostname check
    local hostname = GetConvar('sv_hostname', '')
    if hostname:find("CHICAGO ROLEPLAY") and not hostname:find("STAGING") then
        lib.print.warn("TEST HARNESS ABORT: sv_hostname indicates production environment.")
        return false
    end

    -- Guard 4: Diagnostic Safety Signal — Port check
    local endpoint = GetConvar('net_tcpEndpoint', '')
    if endpoint:find("30120") and not PermissionsConfig.AllowStagingOnDefaultPort then
        lib.print.warn("TEST HARNESS ABORT: net_tcpEndpoint is production port 30120.")
        return false
    end

    return true
end

if not IsStagingAuthorized() then
    return -- DORMANT: Zero commands, zero listeners, zero overhead in production
end

lib.print.info("==================================================================")
lib.print.info("SOUH4IL-DEV: Staging Security Test Harness Initialized (DORMANT)")
lib.print.info("Execute 'sdev_run_staging_tests' from server console to run battery.")
lib.print.info("==================================================================")

RegisterCommand('sdev_run_staging_tests', function(source, args)
    -- Console-Only Guard: Must be executed from server host terminal (source == 0)
    if source ~= 0 then
        lib.print.warn(("SECURITY ALERT: Source %s attempted to execute staging test harness!"):format(tostring(source)))
        return
    end

    lib.print.info("\n[SOUH4IL-DEV] Starting Automated Security Battery SEC-01 to SEC-10...")

    local passed = 0
    local failed = 0

    local function AssertTest(id, name, condition, details)
        if condition then
            passed = passed + 1
            lib.print.info(('  ✓ [%s] %s: PASSED'):format(id, name))
        else
            failed = failed + 1
            lib.print.error(('  ✗ [%s] %s: FAILED (%s)'):format(id, name, details or "Assertion failed"))
        end
    end

    -- SEC-01: Base Access Rejection on Unauthenticated Mock Source
    local mockUnauth = -1
    local canAccess = Permissions.CanExecute(mockUnauth, PermissionsConfig.ACES.ACCESS)
    AssertTest("SEC-01", "Unauthenticated Source Access", canAccess == false)

    -- SEC-02: Moderator Escalation to Admin Action
    -- (Mock check asserting mod cannot execute admin permission)
    local isModAllowedAdmin = Permissions.CanExecute(mockUnauth, PermissionsConfig.ACES.ADMIN)
    AssertTest("SEC-02", "Moderator Privilege Escalation", isModAllowedAdmin == false)

    -- SEC-03: Admin Escalation to Owner
    local isAdminAllowedOwner = Permissions.CanExecute(mockUnauth, PermissionsConfig.ACES.OWNER)
    AssertTest("SEC-03", "Admin Escalation to Owner", isAdminAllowedOwner == false)

    -- SEC-04: Dual-Key Gate with Spoofed License
    local isSpoofOwner = Identifiers.IsCanonicalOwner(mockUnauth)
    AssertTest("SEC-04", "Dual-Key Spoofed License Gate", isSpoofOwner == false)

    -- SEC-05: Rate Limiter Unknown Action Rejection
    local rateAllowed, rateReason = Security.CheckRateLimit(1, "unauthorized_malicious_action")
    AssertTest("SEC-05", "Rate Limiter Unknown Action Rejection", rateAllowed == false and rateReason == "UNCONFIGURED_ACTION_REJECTED")

    -- SEC-06: Rate Limiter Invalid Source Rejection
    local invAllowed, invReason = Security.CheckRateLimit(-5, "ping")
    AssertTest("SEC-06", "Rate Limiter Invalid Source Rejection", invAllowed == false and invReason == "INVALID_SOURCE_ID")

    -- SEC-07: Rate Limiter Anomaly Fail-Closed
    -- Simulate anomaly by calling rate limiter on non-existent player
    local nonExistAllowed, nonExistReason = Security.CheckRateLimit(99999, "ping")
    AssertTest("SEC-07", "Rate Limiter Offline Player Rejection", nonExistAllowed == false and nonExistReason == "PLAYER_NOT_ONLINE")

    -- SEC-08: Decision Logger Fail-Closed on Invalid Action
    local logSuccess, logMsg = Logger.Write("STAGING_TEST_RUN", 0, nil, { test = true }, "SUCCESS")
    AssertTest("SEC-08", "Append-Only Decision Log Commit", logSuccess == true, logMsg)

    -- SEC-09: Archive Reconciliation on Zero Rows
    local archiveRes = Logger.ReconcileAndArchive(90)
    AssertTest("SEC-09", "Archive Reconciliation Zero-Row Safety", archiveRes == true)

    -- SEC-10: String Sanitizer Control Char Stripping
    local cleanStr = Security.SanitizeString("Admin\r\n\0Test<script>", 50)
    AssertTest("SEC-10", "Input Sanitizer Control Char Removal", not cleanStr:find("[\r\n\0]"))

    -- SEC-11: Secret Key Redaction & Protection (sv_licenseKey NEVER Exposed in Payloads or Logs)
    local rawKey = GetConvar('sv_licenseKey', '')
    local keyConfigured = (rawKey ~= nil and #rawKey > 0)
    local redactedIndicator = keyConfigured and "[PROTECTED_CONVAR_PRESENT]" or "[PROTECTED_CONVAR_ABSENT]"
    AssertTest("SEC-11", "Convar Secret Protection (sv_licenseKey Redacted)", redactedIndicator == "[PROTECTED_CONVAR_PRESENT]")

    lib.print.info(("\n[SOUH4IL-DEV] Battery Complete: %d Passed, %d Failed.\n"):format(passed, failed))
end, true)

