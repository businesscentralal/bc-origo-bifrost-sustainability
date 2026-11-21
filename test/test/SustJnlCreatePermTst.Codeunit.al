namespace Origo.Bifrost.Sustainability.Test;

using Origo.Bifrost;
using System.Security.User;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>Issue 7: the empty capability enforces Full even when API roles grant wildcard execution.</summary>
codeunit 98041 "Sust Jnl Create Perm Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Library Assert";
        Fixture: Codeunit "Sust Jnl Create Fixture ori";
        LowerPermissions: Codeunit "Library - Lower Permissions";
        PermissionsMock: Codeunit "Permissions Mock";

    /// <summary>Checks the feature role supplies the native approval read without other installed role extensions.</summary>
    [Test]
    procedure Scenario_ACP_FullGrantsApprovalRead()
    var
        UserSetup: Record "User Setup";
        CanReadUserSetup: Boolean;
    begin
        // Story #7, AC-P | Time: none | Risk: other apps masking a missing feature-role permission
        Assert.IsTrue(PermissionsMock.IsStarted(), 'Permission mocking must be active.');
        LowerPermissions.SetExactPermissionSet('BIFROST SustFull ori');
        CanReadUserSetup := UserSetup.ReadPermission();
        LowerPermissions.SetOutsideO365Scope();
        Assert.IsTrue(CanReadUserSetup, 'The Sustainability Full role must supply the native approval User Setup read.');
    end;

    /// <summary>Checks Read-only refusal and visibility in English.</summary>
    [Test]
    procedure Scenario_ACP_ReadDenied_1033()
    begin
        // Story #7, AC-P | Time: fixed date | Risk: Foundation Read role
        VerifyPermission(false, 1033);
    end;

    /// <summary>Checks Read-only refusal and visibility in Icelandic.</summary>
    [Test]
    procedure Scenario_ACP_ReadDenied_1039()
    begin
        // Story #7, AC-P | Time: fixed date | Risk: Foundation Read role
        VerifyPermission(false, 1039);
    end;

    /// <summary>Checks the Full permission set can create journal lines in English.</summary>
    [Test]
    procedure Scenario_ACP_FullAllowed_1033()
    begin
        // Story #7, AC-P | Time: fixed date | Risk: Foundation Full role
        VerifyPermission(true, 1033);
    end;

    /// <summary>Checks the Full permission set can create journal lines in Icelandic.</summary>
    [Test]
    procedure Scenario_ACP_FullAllowed_1039()
    begin
        // Story #7, AC-P | Time: fixed date | Risk: Foundation Full role
        VerifyPermission(true, 1039);
    end;

    /// <summary>Checks Full-role rollback with open approvals and an existing line in English.</summary>
    [Test]
    procedure Scenario_AC04_ApprovalRollback_1033()
    begin
        // Story #7, AC04/AC-P | Time: fixed date | Risk: approval path and partial writes
        VerifyApprovalRollback(1033);
    end;

    /// <summary>Checks Full-role rollback with open approvals and an existing line in Icelandic.</summary>
    [Test]
    procedure Scenario_AC04_ApprovalRollback_1039()
    begin
        // Story #7, AC04/AC-P | Time: fixed date | Risk: approval path and partial writes
        VerifyApprovalRollback(1039);
    end;

    local procedure VerifyPermission(FullAccess: Boolean; LanguageId: Integer)
    var
        Handler: Interface "Msg Interface ori";
        Response: JsonObject;
        RequestJson: JsonObject;
        Visible: Boolean;
        ApprovalEntryNo: Integer;
    begin
        // [GIVEN] Fixture setup outside mocked permissions, then exactly the intended role.
        Assert.IsTrue(PermissionsMock.IsStarted(), 'Permission mocking must be active.');
        LowerPermissions.SetOutsideO365Scope();
        Fixture.Initialize();
        ApprovalEntryNo := Fixture.CreateUnrelatedOpenApproval();
        RequestJson := Fixture.Request();
        if FullAccess then begin
            LowerPermissions.SetExactPermissionSet('BIFROST Full ori');
            LowerPermissions.AddPermissionSet('BIFROST SustFull ori');
        end else begin
            LowerPermissions.SetExactPermissionSet('BIFROST Read ori');
            LowerPermissions.AddPermissionSet('BIFROST SustRead ori');
        end;
        // Test-only object execution grants no business data or capability permissions.
        LowerPermissions.AddPermissionSet('Sust Jnl Exec ori');
        LowerPermissions.AddPermissionSet('BIFROST API ori');
        Handler := Enum::"Message Type ori"::"Sustainability.Journal.Create";
        // [WHEN] Discovery and the real public dispatcher run under the restricted role.
        Visible := Handler.IsEnabled();
        Response := Fixture.Invoke(RequestJson, LanguageId);
        LowerPermissions.SetOutsideO365Scope();
        Fixture.DeleteOpenApproval(ApprovalEntryNo);
        // [THEN] Read cannot discover or execute the write, while Full can do both.
        Assert.AreEqual(FullAccess, Visible, 'Discovery must reflect the capability permission.');
        if FullAccess then begin
            Fixture.AssertText(Response, 'status', 'Success');
            Fixture.AssertLineCount(1);
        end else begin
            Fixture.AssertText(Response, 'status', 'Error');
            Fixture.AssertText(Response, 'code', 'PermissionDenied');
            Fixture.AssertNoLines();
        end;
    end;

    local procedure VerifyApprovalRollback(LanguageId: Integer)
    var
        RequestJson: JsonObject;
        InvalidLine: JsonObject;
        SeedResponse: JsonObject;
        Response: JsonObject;
        Lines: JsonArray;
        ApprovalEntryNo: Integer;
        BatchApprovalEntryNo: Integer;
    begin
        // [GIVEN] Open unrelated and batch approvals for someone else, outside restricted permissions.
        Assert.IsTrue(PermissionsMock.IsStarted(), 'Permission mocking must be active.');
        LowerPermissions.SetOutsideO365Scope();
        Fixture.Initialize();
        ApprovalEntryNo := Fixture.CreateUnrelatedOpenApproval();
        BatchApprovalEntryNo := Fixture.CreateBatchOpenApproval();
        LowerPermissions.SetExactPermissionSet('BIFROST Full ori');
        LowerPermissions.AddPermissionSet('BIFROST SustFull ori');
        LowerPermissions.AddPermissionSet('Sust Jnl Exec ori');
        LowerPermissions.AddPermissionSet('BIFROST API ori');
        SeedResponse := Fixture.Invoke(Fixture.Request(), LanguageId);

        // [WHEN] A second line fails native validation after the first line was inserted.
        RequestJson := Fixture.Request();
        Lines.Add(Fixture.Line());
        InvalidLine := Fixture.Line();
        InvalidLine.Add('countryRegionCode', 'XINVALID');
        Lines.Add(InvalidLine);
        RequestJson.Replace('lines', Lines);
        Response := Fixture.Invoke(RequestJson, LanguageId);
        LowerPermissions.SetOutsideO365Scope();
        Fixture.DeleteOpenApproval(ApprovalEntryNo);
        Fixture.DeleteOpenApproval(BatchApprovalEntryNo);

        // [THEN] The unrelated approval allows creation; refusal preserves only the original line.
        Fixture.AssertText(SeedResponse, 'status', 'Success');
        Fixture.AssertText(Response, 'status', 'Error');
        Fixture.AssertText(Response, 'code', 'BusinessCentralError');
        Fixture.AssertLineCount(1);
    end;
}
