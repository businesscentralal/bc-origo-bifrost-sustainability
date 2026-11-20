namespace Origo.Bifrost.Sustainability;

using Origo.Bifrost;

/// <summary>
/// Registers Bifrost Sustainability with Foundation for application discovery and setup notifications.
/// Only temporary application metadata is added; Foundation owns all setup notifications.
/// </summary>
codeunit 70009200 "Sust Registration ori"
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"App Registry ori", OnRegisterApps, '', false, false)]
    local procedure RegisterApp(var Apps: Record "Registered App ori" temporary)
    var
        AppRegistry: Codeunit "App Registry ori";
        AppInfo: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(AppInfo);
        AppRegistry.AddApp(Apps, AppInfo.Id(), CopyStr(AppInfo.Name(), 1, 250), 0);
    end;
}
