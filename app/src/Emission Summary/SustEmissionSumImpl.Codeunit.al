namespace Origo.Bifrost.Sustainability;

using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Ledger;
using Microsoft.Sustainability.Setup;
using Origo.Bifrost;

/// <summary>
/// Sustainability.EmissionSummary.Get: sums the posted sustainability ledger by emission scope, period and gas.
/// Read-only: every total is a CalcSums over Microsoft's Sustainability Ledger Entry, nothing is written or committed.
/// </summary>
codeunit 70009207 "Sust Emission Sum Impl ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;
    TableNo = "Message Argument ori";

    var
        DescriptionLbl: Label 'Summarises sustainability emissions by emission scope, period and gas.', MaxLength = 250, Comment = 'is-IS=Tekur saman losun eftir umfangi, tímabili og gastegund.';
        MissingKeyErr: Label 'The required parameter ''%1'' is missing.', Comment = '%1 = parameter name|is-IS=Nauðsynlega færibreytu ''%1'' vantar.';
        UnknownKeyErr: Label 'Unknown parameter ''%1''.', Comment = '%1 = parameter name|is-IS=Óþekkt færibreyta ''%1''.';
        InvalidPeriodErr: Label 'InvalidPeriod: ''%1'' must be a date (YYYY-MM-DD), and fromDate must not be after toDate.', Comment = '%1 = parameter name|is-IS=InvalidPeriod: ''%1'' verður að vera dagsetning (ÁÁÁÁ-MM-DD) og fromDate má ekki vera eftir toDate.';
        DateExpectedLbl: Label 'a date in the form YYYY-MM-DD, with fromDate on or before toDate', Comment = 'is-IS=dagsetning á forminu ÁÁÁÁ-MM-DD þar sem fromDate er sama dag eða á undan toDate';
        DateNextLbl: Label 'Send fromDate and toDate as YYYY-MM-DD dates with fromDate on or before toDate.', Comment = 'is-IS=Sendu fromDate og toDate sem ÁÁÁÁ-MM-DD dagsetningar þar sem fromDate er sama dag eða á undan toDate.';
        UnknownValueErr: Label 'The value ''%2'' of ''%1'' is not allowed. Allowed values: %3.', Comment = '%1 = parameter name, %2 = received value, %3 = allowed values|is-IS=Gildið ''%2'' í ''%1'' er ekki leyft. Leyfð gildi: %3.';
        AllowedValueNextLbl: Label 'Use one of the allowed values and retry.', Comment = 'is-IS=Notaðu eitt af leyfðu gildunum og reyndu aftur.';
        TooManyPeriodsErr: Label 'The result would contain more than %1 periods. Use a larger periodType or a shorter date range.', Comment = '%1 = maximum number of periods|is-IS=Niðurstaðan yrði meira en %1 tímabil. Notaðu stærri periodType eða styttra dagsetningabil.';
        TooManyPeriodsExpectedLbl: Label 'at most %1 periods', Comment = '%1 = maximum number of periods|is-IS=að hámarki %1 tímabil';
        TooManyPeriodsNextLbl: Label 'Choose a larger periodType (for example Month instead of Day) or a shorter date range.', Comment = 'is-IS=Veldu stærri periodType (til dæmis Month í stað Day) eða styttra dagsetningabil.';
        PermissionErr: Label 'Reading emission summaries requires BIFROST SustRead ori and read access to the Sustainability ledger and setup (Microsoft''s Sustainability Read).', Comment = 'is-IS=Til að lesa losunaryfirlit þarf BIFROST SustRead ori og lesaðgang að fjárhag og uppsetningu sjálfbærni (Sustainability Read frá Microsoft).';
        PermissionNextLbl: Label 'Ask an administrator for BIFROST SustRead ori (included in BIFROST Read ori and BIFROST Full ori) and Sustainability Read.', Comment = 'is-IS=Biddu stjórnanda um BIFROST SustRead ori (er hluti af BIFROST Read ori og BIFROST Full ori) og Sustainability Read.';
        ListExpectedLbl: Label 'a list of text values', Comment = 'is-IS=listi af textagildum';
        TextExpectedLbl: Label 'a text value', Comment = 'is-IS=textagildi';
        FixParameterLbl: Label 'Correct the named request parameter and retry.', Comment = 'is-IS=Leiðréttu tilgreinda færibreytu beiðninnar og reyndu aftur.';
        OverviewLbl: Label 'Returns posted sustainability emissions summed per emission scope (Scope 1, Scope 2, Scope 3) and per period between fromDate and toDate: CO2, CH4, N2O, CO2e and carbon fee, plus water, waste and energy totals on request, and a grand total per scope. Units come from Sustainability Setup.', Comment = 'is-IS=Skilar bókaðri losun samanlagðri eftir umfangi (Scope 1, Scope 2, Scope 3) og tímabili frá fromDate til toDate: CO2, CH4, N2O, CO2e og kolefnisgjald, auk vatns-, úrgangs- og orkusamtalna sé þess óskað, og heildarsamtölu fyrir hvert umfang. Einingar koma úr uppsetningu sjálfbærni.';
        NotesLbl: Label 'Read-only and idempotent: totals are database sums over Sustainability Ledger Entry, nothing is written and there is no Commit on the path. Periods follow the calendar (weeks start on Monday) and are clipped to fromDate and toDate; at most 400 periods are returned. Closing-date entries count in the period of their date. Reversed entries and their reversals both count, so they net out. Optional filters emissionScope, countryRegionCode, responsibilityCenter, globalDimension1Code and globalDimension2Code narrow the entries. include accepts water, waste and energy; water adds waterIntensity and dischargedIntoWater, waste adds wasteIntensity, energy adds energyConsumption, summed over the entries of the scope row. Ledger rows outside Scope 1-3 (Water/Waste, Out of Scope, blank) are not summarised.', Comment = 'is-IS=Aðeins lestur og sama niðurstaða við endurtekningu: samtölur eru gagnagrunnssummur úr Sustainability Ledger Entry, engu er breytt og ekkert Commit er á leiðinni. Tímabil fylgja dagatalinu (vikur byrja á mánudegi) og eru skorin við fromDate og toDate; að hámarki eru 400 tímabil skiluð. Færslur á lokadagsetningu teljast á tímabil dagsetningar sinnar. Bakfærðar færslur og bakfærslur þeirra teljast báðar og jafnast því út. Valfrjálsar síur emissionScope, countryRegionCode, responsibilityCenter, globalDimension1Code og globalDimension2Code þrengja færslurnar. include tekur water, waste og energy; water bætir við waterIntensity og dischargedIntoWater, waste bætir við wasteIntensity, energy bætir við energyConsumption, samanlagt yfir færslur umfangsins. Færslur utan Scope 1-3 (Water/Waste, Out of Scope, autt) eru ekki teknar saman.';
        MaxPeriods: Integer;

    trigger OnRun()
    begin
        PerformRead(Rec);
    end;

    /// <summary>Validates the envelope and runs the read in its own transaction scope so a refusal is a structured error.</summary>
    /// <param name="Argument">The Foundation message argument.</param>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Argument.AssertVersion1();
        Argument.AssertIsLicensed();
        if Argument."Omit Commit" then begin
            PerformRead(Argument);
            exit;
        end;
        if not Codeunit.Run(Codeunit::"Sust Emission Sum Impl ori", Argument) then
            Argument.RespondWithLastError();
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure PerformRead(var Argument: Record "Message Argument ori")
    var
        SustainabilitySetup: Record "Sustainability Setup";
        Request: JsonObject;
        Response: JsonObject;
        Units: JsonObject;
        Rows: JsonArray;
        Totals: JsonArray;
        Scopes: List of [Integer];
        Includes: List of [Text];
        PeriodStarts: List of [Date];
        PeriodEnds: List of [Date];
        FromDate: Date;
        ToDate: Date;
        PeriodType: Text;
        ParameterName: Text;
        ScopeOrdinal: Integer;
        Index: Integer;
    begin
        MaxPeriods := 400;
        if not HasReadAccess() then
            Refuse(Argument, "Bifrost Error Code ori"::PermissionDenied, PermissionErr, 'permissionSet', '', 'BIFROST SustRead ori', PermissionNextLbl);
        Request := Argument.GetRequestJson();
        foreach ParameterName in Request.Keys() do
            if not (ParameterName in ['fromDate', 'toDate', 'periodType', 'emissionScope', 'countryRegionCode', 'responsibilityCenter', 'globalDimension1Code', 'globalDimension2Code', 'include']) then
                Refuse(Argument, "Bifrost Error Code ori"::UnknownParameter, StrSubstNo(UnknownKeyErr, ParameterName), ParameterName, '', AllowedKeys(), FixParameterLbl);
        FromDate := ReadDate(Argument, Request, 'fromDate');
        ToDate := ReadDate(Argument, Request, 'toDate');
        if FromDate > ToDate then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidPeriodErr, 'fromDate'), 'fromDate', Format(FromDate, 0, 9), DateExpectedLbl, DateNextLbl);
        PeriodType := ReadAllowedText(Argument, Request, 'periodType', 'Month', AllowedPeriodTypes());
        ReadScopes(Argument, Request, Scopes);
        ReadIncludes(Argument, Request, Includes);
        BuildPeriods(Argument, FromDate, ToDate, PeriodType, PeriodStarts, PeriodEnds);

        foreach ScopeOrdinal in Scopes do begin
            for Index := 1 to PeriodStarts.Count() do
                Rows.Add(SumEntries(Request, ScopeOrdinal, PeriodStarts.Get(Index), PeriodEnds.Get(Index), Includes, true));
            Totals.Add(SumEntries(Request, ScopeOrdinal, FromDate, ToDate, Includes, false));
        end;

        SustainabilitySetup.SetLoadFields("Emission Unit of Measure Code", "Water Unit of Measure Code", "Waste Unit of Measure Code", "Disch. Into Water Unit of Meas", "Energy Unit of Measure Code");
        if not SustainabilitySetup.Get() then
            Clear(SustainabilitySetup);
        Units.Add('emission', SustainabilitySetup."Emission Unit of Measure Code");
        Units.Add('carbonFee', 'LCY');
        if Includes.Contains('water') then begin
            Units.Add('water', SustainabilitySetup."Water Unit of Measure Code");
            Units.Add('dischargedIntoWater', SustainabilitySetup."Disch. Into Water Unit of Meas");
        end;
        if Includes.Contains('waste') then
            Units.Add('waste', SustainabilitySetup."Waste Unit of Measure Code");
        if Includes.Contains('energy') then
            Units.Add('energy', SustainabilitySetup."Energy Unit of Measure Code");

        Response.Add('status', 'Success');
        Response.Add('fromDate', Format(FromDate, 0, 9));
        Response.Add('toDate', Format(ToDate, 0, 9));
        Response.Add('periodType', PeriodType);
        Response.Add('noOfPeriods', PeriodStarts.Count());
        Response.Add('units', Units);
        Response.Add('rows', Rows);
        Response.Add('totals', Totals);
        Argument.SetResponseJson(Response);
        Argument."Content Type" := Argument.GetContentTypeJson();
    end;

    local procedure HasReadAccess(): Boolean
    var
        EmissionAccess: Record "Sust Emission Access ori";
        LedgerEntry: Record "Sustainability Ledger Entry";
        SustainabilitySetup: Record "Sustainability Setup";
    begin
        // BIFROST SustRead ori grants the capability; the native table reads come from Microsoft's Sustainability permission sets.
        exit(EmissionAccess.ReadPermission() and LedgerEntry.ReadPermission() and SustainabilitySetup.ReadPermission());
    end;

    local procedure SumEntries(Request: JsonObject; ScopeOrdinal: Integer; StartDate: Date; EndDate: Date; Includes: List of [Text]; IsPeriodRow: Boolean) Row: JsonObject
    var
        LedgerEntry: Record "Sustainability Ledger Entry";
    begin
        LedgerEntry.SetRange("Emission Scope", Enum::"Emission Scope".FromInteger(ScopeOrdinal));
        LedgerEntry.SetRange("Posting Date", StartDate, ClosingDate(EndDate));
        ApplyCodeFilter(Request, 'countryRegionCode', LedgerEntry, LedgerEntry.FieldNo("Country/Region Code"));
        ApplyCodeFilter(Request, 'responsibilityCenter', LedgerEntry, LedgerEntry.FieldNo("Responsibility Center"));
        ApplyCodeFilter(Request, 'globalDimension1Code', LedgerEntry, LedgerEntry.FieldNo("Global Dimension 1 Code"));
        ApplyCodeFilter(Request, 'globalDimension2Code', LedgerEntry, LedgerEntry.FieldNo("Global Dimension 2 Code"));
        LedgerEntry.CalcSums("Emission CO2", "Emission CH4", "Emission N2O", "CO2e Emission", "Carbon Fee", "Water Intensity", "Discharged Into Water", "Waste Intensity", "Energy Consumption");
        Row.Add('scope', ToScopeName(ScopeOrdinal));
        if IsPeriodRow then begin
            Row.Add('periodStart', Format(StartDate, 0, 9));
            Row.Add('periodEnd', Format(EndDate, 0, 9));
        end;
        Row.Add('CO2', LedgerEntry."Emission CO2");
        Row.Add('CH4', LedgerEntry."Emission CH4");
        Row.Add('N2O', LedgerEntry."Emission N2O");
        Row.Add('CO2e', LedgerEntry."CO2e Emission");
        Row.Add('carbonFee', LedgerEntry."Carbon Fee");
        if Includes.Contains('water') then begin
            Row.Add('waterIntensity', LedgerEntry."Water Intensity");
            Row.Add('dischargedIntoWater', LedgerEntry."Discharged Into Water");
        end;
        if Includes.Contains('waste') then
            Row.Add('wasteIntensity', LedgerEntry."Waste Intensity");
        if Includes.Contains('energy') then
            Row.Add('energyConsumption', LedgerEntry."Energy Consumption");
    end;

    local procedure ApplyCodeFilter(Request: JsonObject; ParameterName: Text; var LedgerEntry: Record "Sustainability Ledger Entry"; FieldNo: Integer)
    var
        RecRef: RecordRef;
        Token: JsonToken;
    begin
        if not Request.Get(ParameterName, Token) then
            exit;
        RecRef.GetTable(LedgerEntry);
        RecRef.Field(FieldNo).SetRange(Token.AsValue().AsText());
        RecRef.SetTable(LedgerEntry);
    end;

    local procedure BuildPeriods(var Argument: Record "Message Argument ori"; FromDate: Date; ToDate: Date; PeriodType: Text; var PeriodStarts: List of [Date]; var PeriodEnds: List of [Date])
    var
        PeriodStart: Date;
        NextStart: Date;
    begin
        PeriodStart := FromDate;
        while PeriodStart <= ToDate do begin
            if PeriodStarts.Count() >= MaxPeriods then
                Refuse(Argument, "Bifrost Error Code ori"::LimitExceeded, StrSubstNo(TooManyPeriodsErr, MaxPeriods), 'periodType', PeriodType, StrSubstNo(TooManyPeriodsExpectedLbl, MaxPeriods), TooManyPeriodsNextLbl);
            NextStart := CalcDate(PeriodLength(PeriodType), CalcDate(PeriodStartFormula(PeriodType), PeriodStart));
            PeriodStarts.Add(PeriodStart);
            if NextStart - 1 > ToDate then
                PeriodEnds.Add(ToDate)
            else
                PeriodEnds.Add(NextStart - 1);
            PeriodStart := NextStart;
        end;
    end;

    local procedure PeriodStartFormula(PeriodType: Text): Text
    begin
        case PeriodType of
            'Week':
                exit('<-CW>');
            'Month':
                exit('<-CM>');
            'Quarter':
                exit('<-CQ>');
            'Year':
                exit('<-CY>');
        end;
        exit('<0D>');
    end;

    local procedure PeriodLength(PeriodType: Text): Text
    begin
        case PeriodType of
            'Week':
                exit('<1W>');
            'Month':
                exit('<1M>');
            'Quarter':
                exit('<1Q>');
            'Year':
                exit('<1Y>');
        end;
        exit('<1D>');
    end;

    local procedure ReadDate(var Argument: Record "Message Argument ori"; Request: JsonObject; ParameterName: Text) Value: Date
    var
        Token: JsonToken;
        Received: Text;
    begin
        if not Request.Get(ParameterName, Token) then
            Refuse(Argument, "Bifrost Error Code ori"::MissingParameter, StrSubstNo(MissingKeyErr, ParameterName), ParameterName, '', DateExpectedLbl, DateNextLbl);
        Token.WriteTo(Received);
        if not Token.IsValue() then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidPeriodErr, ParameterName), ParameterName, Received, DateExpectedLbl, DateNextLbl);
        if Token.AsValue().IsNull() then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidPeriodErr, ParameterName), ParameterName, Received, DateExpectedLbl, DateNextLbl);
        if not Evaluate(Value, Token.AsValue().AsText(), 9) then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidPeriodErr, ParameterName), ParameterName, Received, DateExpectedLbl, DateNextLbl);
        if Value = 0D then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidPeriodErr, ParameterName), ParameterName, Received, DateExpectedLbl, DateNextLbl);
    end;

    local procedure ReadAllowedText(var Argument: Record "Message Argument ori"; Request: JsonObject; ParameterName: Text; DefaultValue: Text; Allowed: List of [Text]) Value: Text
    var
        Token: JsonToken;
    begin
        if not Request.Get(ParameterName, Token) then
            exit(DefaultValue);
        Value := ReadTextToken(Argument, Token, ParameterName);
        if not Allowed.Contains(Value) then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(UnknownValueErr, ParameterName, Value, JoinList(Allowed)), ParameterName, Value, JoinList(Allowed), AllowedValueNextLbl);
    end;

    local procedure ReadScopes(var Argument: Record "Message Argument ori"; Request: JsonObject; var Scopes: List of [Integer])
    var
        Allowed: List of [Text];
        Value: Text;
        Index: Integer;
    begin
        Allowed.Add('Scope 1');
        Allowed.Add('Scope 2');
        Allowed.Add('Scope 3');
        if Request.Contains('emissionScope') then begin
            Value := ReadAllowedText(Argument, Request, 'emissionScope', '', Allowed);
            Scopes.Add(ToScopeOrdinal(Value));
            exit;
        end;
        for Index := 1 to Allowed.Count() do
            Scopes.Add(ToScopeOrdinal(Allowed.Get(Index)));
    end;

    local procedure ReadIncludes(var Argument: Record "Message Argument ori"; Request: JsonObject; var Includes: List of [Text])
    var
        Allowed: List of [Text];
        Token: JsonToken;
        Item: JsonToken;
        Received: Text;
        Value: Text;
    begin
        if not Request.Get('include', Token) then
            exit;
        Allowed.Add('water');
        Allowed.Add('waste');
        Allowed.Add('energy');
        if not Token.IsArray() then begin
            Token.WriteTo(Received);
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(UnknownValueErr, 'include', Received, JoinList(Allowed)), 'include', Received, ListExpectedLbl, AllowedValueNextLbl);
        end;
        foreach Item in Token.AsArray() do begin
            Value := ReadTextToken(Argument, Item, 'include');
            if not Allowed.Contains(Value) then
                Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(UnknownValueErr, 'include', Value, JoinList(Allowed)), 'include', Value, JoinList(Allowed), AllowedValueNextLbl);
            if not Includes.Contains(Value) then
                Includes.Add(Value);
        end;
    end;

    local procedure ReadTextToken(var Argument: Record "Message Argument ori"; Token: JsonToken; ParameterName: Text): Text
    var
        Serialized: Text;
    begin
        Token.WriteTo(Serialized);
        if CopyStr(Serialized, 1, 1) <> '"' then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(UnknownValueErr, ParameterName, Serialized, TextExpectedLbl), ParameterName, Serialized, TextExpectedLbl, FixParameterLbl);
        exit(Token.AsValue().AsText());
    end;

    local procedure ToScopeOrdinal(Name: Text): Integer
    begin
        case Name of
            'Scope 1':
                exit(Enum::"Emission Scope"::"Scope 1".AsInteger());
            'Scope 2':
                exit(Enum::"Emission Scope"::"Scope 2".AsInteger());
        end;
        exit(Enum::"Emission Scope"::"Scope 3".AsInteger());
    end;

    local procedure ToScopeName(Ordinal: Integer): Text
    begin
        case Ordinal of
            Enum::"Emission Scope"::"Scope 1".AsInteger():
                exit('Scope 1');
            Enum::"Emission Scope"::"Scope 2".AsInteger():
                exit('Scope 2');
        end;
        exit('Scope 3');
    end;

    local procedure AllowedPeriodTypes() Allowed: List of [Text]
    begin
        Allowed.Add('Day');
        Allowed.Add('Week');
        Allowed.Add('Month');
        Allowed.Add('Quarter');
        Allowed.Add('Year');
    end;

    local procedure AllowedKeys(): Text
    begin
        exit('fromDate, toDate, periodType, emissionScope, countryRegionCode, responsibilityCenter, globalDimension1Code, globalDimension2Code, include');
    end;

    local procedure JoinList(Values: List of [Text]) Joined: Text
    var
        Value: Text;
    begin
        foreach Value in Values do begin
            if Joined <> '' then
                Joined += ', ';
            Joined += Value;
        end;
    end;

    local procedure Refuse(var Argument: Record "Message Argument ori"; ErrorCode: Enum "Bifrost Error Code ori"; Message: Text; Parameter: Text; Received: Text; Expected: Text; NextStep: Text)
    begin
        // Foundation carries the structured collection across the transaction rollback.
        Argument.AddError(ErrorCode, Message, Parameter, Received, Expected, NextStep);
        Argument.RaiseCollectedErrors(ErrorCode, Message);
    end;

    /// <summary>
    /// Shown in the roster when the user can read emission summaries.
    /// The shared Sustainability-configured check from issue #1 is added here when it merges.
    /// </summary>
    /// <returns>True when the type is listed in the roster.</returns>
    procedure IsEnabled(): Boolean
    begin
        exit(HasReadAccess());
    end;

    /// <summary>Provides the GetFilterTableNo discovery chapter.</summary>
    /// <returns>The Sustainability Ledger Entry table number.</returns>
    procedure GetFilterTableNo(): Integer
    begin
        exit(Database::"Sustainability Ledger Entry");
    end;

    /// <summary>Provides the GetDescription discovery chapter.</summary>
    /// <returns>The translated description.</returns>
    procedure GetDescription(): Text[250]
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>Provides the GetMessageDirection discovery chapter.</summary>
    /// <returns>Outbound: the type reads data.</returns>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Outbound);
    end;

    /// <summary>Provides the GetKeywords discovery chapter.</summary>
    /// <returns>The translated keywords.</returns>
    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'Sustainability.EmissionSummary.Get, sustainability, emission, emissions, CO2, CO2e, greenhouse gas, scope 1, scope 2, scope 3, carbon fee, ESG', Comment = 'is-IS=Sustainability.EmissionSummary.Get, sjálfbærni, losun, útblástur, CO2, CO2e, gróðurhúsalofttegund, umfang 1, umfang 2, umfang 3, kolefnisgjald, UFS';
    begin
        exit(KeywordsLbl);
    end;

    /// <summary>Provides the GetSelectionDescription discovery chapter.</summary>
    /// <returns>The translated description.</returns>
    procedure GetSelectionDescription(): Text
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>Provides the overview contract chapter.</summary>
    /// <param name="Overview">Receives the overview.</param>
    /// <returns>True.</returns>
    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := OverviewLbl;
        exit(true);
    end;

    /// <summary>Provides the notes contract chapter.</summary>
    /// <param name="Notes">Receives the notes.</param>
    /// <returns>True.</returns>
    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := NotesLbl;
        exit(true);
    end;

    /// <summary>Provides the envelope contract chapter.</summary>
    /// <param name="Envelope">Receives the envelope.</param>
    /// <returns>True.</returns>
    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    begin
        Envelope.ReadFrom('{"subject":{"use":"notUsed"},"dataRequired":true,"version":"1.0","contentType":"application/json"}');
        exit(true);
    end;

    /// <summary>Provides the target contract chapter.</summary>
    /// <param name="Target">Receives the target.</param>
    /// <returns>True.</returns>
    procedure GetTarget(var Target: JsonArray): Boolean
    begin
        Target.ReadFrom('[{"source":"data.fromDate, data.toDate","form":"Date range","description":"Posting date range of the Sustainability Ledger Entry rows that are summed."}]');
        exit(true);
    end;

    /// <summary>Provides the parameters contract chapter.</summary>
    /// <param name="Parameters">Receives the parameters.</param>
    /// <returns>True.</returns>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Clear(Parameters);
        Parameters.Add(ContractMgt.Parameter('fromDate', 'string', true, 'First posting date, YYYY-MM-DD.'));
        Parameters.Add(ContractMgt.Parameter('toDate', 'string', true, 'Last posting date, YYYY-MM-DD, on or after fromDate.'));
        Parameters.Add(ContractMgt.Parameter('periodType', 'string', false, 'Day, Week, Month, Quarter or Year. Default Month. At most 400 periods.'));
        Parameters.Add(ContractMgt.Parameter('emissionScope', 'string', false, 'Scope 1, Scope 2 or Scope 3. Default: all three.'));
        Parameters.Add(ContractMgt.Parameter('countryRegionCode', 'string', false, 'Only entries with this Country/Region Code.'));
        Parameters.Add(ContractMgt.Parameter('responsibilityCenter', 'string', false, 'Only entries with this Responsibility Center.'));
        Parameters.Add(ContractMgt.Parameter('globalDimension1Code', 'string', false, 'Only entries with this Global Dimension 1 Code.'));
        Parameters.Add(ContractMgt.Parameter('globalDimension2Code', 'string', false, 'Only entries with this Global Dimension 2 Code.'));
        Parameters.Add(ContractMgt.Parameter('include', 'array', false, 'Extra totals: any of water, waste, energy.'));
        exit(true);
    end;

    /// <summary>Provides the response contract chapter.</summary>
    /// <param name="Response">Receives the response description.</param>
    /// <returns>True.</returns>
    procedure GetResponse(var Response: JsonObject): Boolean
    begin
        Response.ReadFrom('{"contentType":"application/json","fields":[{"name":"status","type":"string","description":"Success."},{"name":"fromDate","type":"string","description":"Requested first date."},{"name":"toDate","type":"string","description":"Requested last date."},{"name":"periodType","type":"string","description":"Period type used."},{"name":"noOfPeriods","type":"integer","description":"Number of periods per scope."},{"name":"units","type":"object","description":"Units from Sustainability Setup: emission, carbonFee (LCY) and, when included, water, dischargedIntoWater, waste, energy."},{"name":"rows","type":"array","description":"One row per scope and period: scope, periodStart, periodEnd, CO2, CH4, N2O, CO2e, carbonFee and the included waterIntensity, dischargedIntoWater, wasteIntensity, energyConsumption."},{"name":"totals","type":"array","description":"One grand total per scope over fromDate..toDate with the same amounts."}]}');
        exit(true);
    end;

    /// <summary>Provides the errors contract chapter.</summary>
    /// <param name="Errors">Receives the error entries.</param>
    /// <returns>True.</returns>
    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Clear(Errors);
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::MissingParameter, StrSubstNo(MissingKeyErr, 'fromDate / toDate'), DateNextLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidPeriodErr, 'fromDate / toDate'), DateNextLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::InvalidParameter, StrSubstNo(UnknownValueErr, 'periodType / emissionScope / include', '...', 'Day, Week, Month, Quarter, Year / Scope 1, Scope 2, Scope 3 / water, waste, energy'), AllowedValueNextLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::LimitExceeded, StrSubstNo(TooManyPeriodsErr, 400), TooManyPeriodsNextLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::UnknownParameter, StrSubstNo(UnknownKeyErr, 'data'), FixParameterLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, PermissionErr, PermissionNextLbl));
        exit(true);
    end;

    /// <summary>Provides the effect contract chapter.</summary>
    /// <param name="Effect">Receives the effect.</param>
    /// <returns>True.</returns>
    procedure GetEffect(var Effect: JsonObject): Boolean
    begin
        Effect.ReadFrom('{"effect":"read","changes":"Nothing; sums Sustainability Ledger Entry rows. No Commit on the path and no sustainability posting.","idempotent":true,"permissionSet":"BIFROST SustRead ori","preconditions":["BIFROST SustRead ori (included in BIFROST Read ori and BIFROST Full ori).","Read permission on Sustainability Ledger Entry and Sustainability Setup, for example Microsoft''s Sustainability Read."]}');
        exit(true);
    end;

    /// <summary>Provides the examples contract chapter.</summary>
    /// <param name="Examples">Receives the examples.</param>
    /// <returns>True.</returns>
    procedure GetExamples(var Examples: JsonArray): Boolean
    begin
        Examples.ReadFrom('[{"title":"Scope 1 per quarter","request":{"type":"Sustainability.EmissionSummary.Get","data":{"fromDate":"2026-01-01","toDate":"2026-06-30","periodType":"Quarter","emissionScope":"Scope 1"}},"response":{"status":"Success","fromDate":"2026-01-01","toDate":"2026-06-30","periodType":"Quarter","noOfPeriods":2,"units":{"emission":"KG","carbonFee":"LCY"},"rows":[{"scope":"Scope 1","periodStart":"2026-01-01","periodEnd":"2026-03-31","CO2":120.5,"CH4":0.4,"N2O":0.1,"CO2e":140.2,"carbonFee":12.5},{"scope":"Scope 1","periodStart":"2026-04-01","periodEnd":"2026-06-30","CO2":98,"CH4":0.3,"N2O":0.1,"CO2e":115.7,"carbonFee":10}],"totals":[{"scope":"Scope 1","CO2":218.5,"CH4":0.7,"N2O":0.2,"CO2e":255.9,"carbonFee":22.5}]}}]');
        exit(true);
    end;

    /// <summary>Declares no metering chapter.</summary>
    /// <param name="Metering">Cleared.</param>
    /// <returns>False.</returns>
    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        Clear(Metering);
        exit(false);
    end;

    /// <summary>Declares no related chapter.</summary>
    /// <param name="Related">Cleared.</param>
    /// <returns>False.</returns>
    procedure GetRelated(var Related: JsonArray): Boolean
    begin
        Clear(Related);
        exit(false);
    end;

    /// <summary>Declares no workflow chapter.</summary>
    /// <param name="Workflow">Cleared.</param>
    /// <returns>False.</returns>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        Clear(Workflow);
        exit(false);
    end;
}
