namespace Origo.Bifrost.Sustainability.Test;

using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Scorecard;
using Microsoft.Sustainability.Setup;
using Origo.Bifrost;
using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

/// <summary>Issue 6: permissions (AC-P) and visibility (AC-V) of Sustainability.Goal.Set.</summary>
codeunit 98036 "Sust Goal Set Perm Tst ori"
{
    Subtype = Test;
    TestPermissions = Restrictive;

    var
        Assert: Codeunit "Library Assert";
        LowerPermissions: Codeunit "Library - Lower Permissions";

    /// <summary>The read role does not see the type, even in a configured company.</summary>
    [Test]
    procedure Scenario_ACP_ReadRole_TypeIsHidden()
    var
        Impl: Interface "Msg Interface ori";
        Enabled: Boolean;
    begin
        // Story #6, AC-P | Time: no date-dependent inputs | Risk: permissions restored
        SetConfigured(true);
        Impl := Enum::"Message Type ori"::"Sustainability.Goal.Set";
        // Foundation Read supplies execution; Sustainability Read and test setup supply reads (#18).
        LowerPermissions.SetExactPermissionSet('BIFROST Read ori');
        LowerPermissions.AddPermissionSet('BIFROST SustRead ori');
        LowerPermissions.AddPermissionSet('Sust Setup Test ori');
        Enabled := Impl.IsEnabled();
        LowerPermissions.SetOutsideO365Scope();
        Assert.IsFalse(Enabled, 'The read role must not see Goal.Set.');
    end;

    /// <summary>A read caller is refused with PermissionDenied and no scorecard is written.</summary>
    [Test]
    procedure Scenario_ACP_ReadCaller_IsRefused()
    var
        Setup: Record "Setup ori";
        Scorecard: Record "Sustainability Scorecard";
        Dispatcher: Codeunit "Dispatcher ori";
        Request: BigText;
        Response: BigText;
        ResponseType: Text[100];
        ResponseText: Text;
        ResponseJson: JsonObject;
        BeforeCount: Integer;
    begin
        // Story #6, AC-P | Time: no date-dependent inputs | Risk: permissions restored
        LowerPermissions.SetOutsideO365Scope();
        Setup.InsertIfNotExists();
        BeforeCount := Scorecard.Count();
        Commit();
        LowerPermissions.SetExactPermissionSet('BIFROST API ori');
        LowerPermissions.AddPermissionSet('BIFROST SustRead ori');
        Request.AddText('{"scorecardNo":"SC6-READ"}');
        Dispatcher.Execute(Enum::"Message Type ori"::"Sustainability.Goal.Set", Enum::"Message Version ori"::"1.0", '', 'issue6-permissions', 'application/json', Request, Response, ResponseType, false);
        Response.GetSubText(ResponseText, 1);
        LowerPermissions.SetOutsideO365Scope();
        ResponseJson.ReadFrom(ResponseText);
        Assert.AreEqual('Error', ResponseJson.GetText('status'), ResponseText);
        Assert.AreEqual('PermissionDenied', ResponseJson.GetText('code'), ResponseText);
        Assert.AreEqual(BeforeCount, Scorecard.Count(), 'A permission refusal must not write a scorecard.');
    end;

    /// <summary>Foundation Full includes the type: with Microsoft's Sustainability Read set it is visible in a configured company.</summary>
    [Test]
    procedure Scenario_ACV_FullRole_ConfiguredCompany_TypeIsVisible()
    var
        Impl: Interface "Msg Interface ori";
        Enabled: Boolean;
    begin
        // Story #6, AC-V/AC-P | Time: no date-dependent inputs | Risk: isolation rolls back the setup change
        SetConfigured(true);
        Impl := Enum::"Message Type ori"::"Sustainability.Goal.Set";
        // Role users read Microsoft Sustainability data with their own Business Central permissions (#1, AS0110/AS0112)
        LowerPermissions.SetExactPermissionSet('BIFROST Full ori');
        LowerPermissions.AddPermissionSet('Sustainability Read');
        Enabled := Impl.IsEnabled();
        LowerPermissions.SetOutsideO365Scope();
        Assert.IsTrue(Enabled, 'Foundation Full must see Goal.Set when Sustainability is configured.');
    end;

    /// <summary>In an unconfigured company the type is hidden, but a caller that knows it can still run it.</summary>
    [Test]
    procedure Scenario_ACV_UnconfiguredCompany_HiddenButRuns()
    var
        Dispatcher: Codeunit "Dispatcher ori";
        Request: BigText;
        Response: BigText;
        ResponseType: Text[100];
        ResponseText: Text;
        ResponseJson: JsonObject;
        Enabled: Boolean;
        Impl: Interface "Msg Interface ori";
    begin
        // Story #6, AC-V | Time: no date-dependent inputs | Risk: isolation rolls back the setup change
        SetConfigured(false);
        Impl := Enum::"Message Type ori"::"Sustainability.Goal.Set";
        Enabled := Impl.IsEnabled();
        Assert.IsFalse(Enabled, 'Goal.Set must be hidden when Sustainability is not configured.');
        Request.AddText('{"name":"Hidden but callable"}');
        Dispatcher.Execute(Enum::"Message Type ori"::"Sustainability.Goal.Set", Enum::"Message Version ori"::"1.0", '', 'issue6-visibility', 'application/json', Request, Response, ResponseType, false);
        Response.GetSubText(ResponseText, 1);
        ResponseJson.ReadFrom(ResponseText);
        Assert.AreEqual('MissingParameter', ResponseJson.GetText('code'), 'A hidden type still runs its own checks: ' + ResponseText);
    end;

    local procedure SetConfigured(Configured: Boolean)
    var
        SustainabilitySetup: Record "Sustainability Setup";
        SustainabilityAccount: Record "Sustainability Account";
        BifrostSetup: Record "Setup ori";
    begin
        LowerPermissions.SetOutsideO365Scope();
        BifrostSetup.InsertIfNotExists();
        if not SustainabilitySetup.Get() then begin
            SustainabilitySetup.Init();
            SustainabilitySetup.Insert();
        end;
        if Configured then
            SustainabilitySetup."Emission Unit of Measure Code" := 'KG'
        else begin
            SustainabilitySetup."Emission Unit of Measure Code" := '';
            SustainabilityAccount.DeleteAll();
        end;
        SustainabilitySetup.Modify();
    end;
}
