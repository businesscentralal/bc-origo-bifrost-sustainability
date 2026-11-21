namespace Origo.Bifrost.Sustainability;

using Microsoft.Sustainability.Scorecard;
using Origo.Bifrost;

/// <summary>
/// Creates or updates a sustainability scorecard and the goals listed in the request through the standard
/// Sustainability Scorecard and Sustainability Goal tables, so Business Central's own field validation runs.
/// Goals that are not listed are left as they are. Nothing is posted.
/// </summary>
codeunit 70009212 "Sust Goal Set Impl ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;
    TableNo = "Message Argument ori";

    trigger OnRun()
    var
        Request: JsonObject;
        ScorecardNo: Code[20];
    begin
        Request := Rec.GetRequestJson();
        ScorecardNo := CopyStr(Request.GetText('scorecardNo'), 1, MaxStrLen(ScorecardNo));
        Apply(ScorecardNo, Request);
        RespondWithScorecard(Rec, ScorecardNo);
    end;

    var
        PermissionErr: Label 'You need BIFROST SustFull ori to create or update sustainability scorecards and goals.', Comment = 'is-IS=Þú þarft BIFROST SustFull ori til að stofna eða uppfæra sjálfbærniskorkort og markmið.';
        PermissionNextTxt: Label 'Ask an administrator for the Bifrost Sustainability Full role, which Bifrost Full includes.', Comment = 'is-IS=Biddu stjórnanda um hlutverkið Bifrost Sustainability Full sem Bifrost Full inniheldur.';
        MissingScorecardErr: Label 'scorecardNo is required. Nothing was changed.', Comment = 'is-IS=scorecardNo er áskilið. Engu var breytt.';
        MissingGoalNoErr: Label 'Every goal needs a no. Nothing was changed.', Comment = 'is-IS=Hvert markmið þarf no. Engu var breytt.';
        UnknownKeyErr: Label 'Unknown parameter %1. Nothing was changed.', Comment = '%1 = request key, is-IS=Óþekkt viðfang %1. Engu var breytt.';
        InvalidValueErr: Label 'The value of %1 is not valid. Nothing was changed.', Comment = '%1 = request key, is-IS=Gildið í %1 er ekki gilt. Engu var breytt.';
        InvalidPeriodErr: Label 'InvalidPeriod: %1 Nothing was changed.', Comment = '%1 = the period rule that failed, is-IS=InvalidPeriod: %1 Engu var breytt.';
        EndBeforeStartTxt: Label 'The end date of goal %1 is before its start date.', Comment = '%1 = goal no., is-IS=Lokadagsetning markmiðs %1 er á undan upphafsdagsetningu þess.';
        BaselineEndBeforeStartTxt: Label 'The baseline end date of goal %1 is before its baseline start date.', Comment = '%1 = goal no., is-IS=Lokadagsetning grunnlínu markmiðs %1 er á undan upphafsdagsetningu grunnlínunnar.';
        BaselineNotBeforeGoalTxt: Label 'The baseline period of goal %1 must end before the goal period starts.', Comment = '%1 = goal no., is-IS=Grunnlínutímabil markmiðs %1 verður að enda áður en markmiðstímabilið hefst.';
        FixScorecardTxt: Label 'Send scorecardNo with the scorecard number, at most 20 characters.', Comment = 'is-IS=Sendu scorecardNo með númeri skorkortsins, að hámarki 20 stafi.';
        FixKeyTxt: Label 'Use only the keys listed in the contract of Sustainability.Goal.Set.', Comment = 'is-IS=Notaðu aðeins lyklana sem eru taldir upp í samningi Sustainability.Goal.Set.';
        FixValueTxt: Label 'Send dates as YYYY-MM-DD, numbers as JSON numbers, mainGoal as true or false and texts within the field length.', Comment = 'is-IS=Sendu dagsetningar sem ÁÁÁÁ-MM-DD, tölur sem JSON-tölur, mainGoal sem true eða false og texta innan lengdar svæðisins.';
        FixPeriodTxt: Label 'Send a start date on or before the end date, and a baseline period that ends before the goal period starts.', Comment = 'is-IS=Sendu upphafsdagsetningu sem er sama dag eða á undan lokadagsetningu og grunnlínutímabil sem endar áður en markmiðstímabilið hefst.';
        ExpectedScorecardTxt: Label 'a scorecard number', Comment = 'is-IS=númer skorkorts';
        GoalPathTok: Label 'goals[%1]', Comment = '%1 = zero-based goal index', Locked = true;
        ExpectedPeriodTxt: Label 'a valid goal and baseline period', Comment = 'is-IS=gilt markmiðs- og grunnlínutímabil';

    /// <summary>Shows the type when Sustainability is configured and the caller has the write grant.</summary>
    /// <returns>True when the type is listed in the roster.</returns>
    procedure IsEnabled(): Boolean
    var
        SustConfigured: Codeunit "Sust Configured ori";
    begin
        if not HasWriteGrant() then
            exit(false);
        exit(SustConfigured.IsConfigured());
    end;

    /// <summary>Identifies the table this type changes.</summary>
    /// <returns>The Sustainability Goal table number.</returns>
    procedure GetFilterTableNo(): Integer
    begin
        exit(Database::"Sustainability Goal");
    end;

    /// <summary>Describes the type.</summary>
    /// <returns>A short description.</returns>
    procedure GetDescription(): Text[250]
    var
        DescriptionLbl: Label 'Creates or updates a sustainability scorecard and its goals with the standard validation. Goals that are not listed are left as they are. Nothing is posted.', Comment = 'is-IS=Stofnar eða uppfærir sjálfbærniskorkort og markmið þess með staðlaðri sannprófun. Markmið sem ekki eru talin upp haldast óbreytt. Ekkert er bókað.';
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>Provides translated discovery terms.</summary>
    /// <returns>Comma-separated search terms.</returns>
    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'sustainability, scorecard, goal, target, emission target, baseline, main goal', Comment = 'is-IS=sjálfbærni, skorkort, markmið, viðmið, losunarmarkmið, grunnlína, aðalmarkmið';
    begin
        exit(KeywordsLbl);
    end;

    /// <summary>Explains when to select the type.</summary>
    /// <returns>The same text as the description.</returns>
    procedure GetSelectionDescription(): Text
    begin
        exit(GetDescription());
    end;

    /// <summary>Declares the inbound direction.</summary>
    /// <returns>Inbound.</returns>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    /// <summary>Checks the request completely, then writes the scorecard and goals in one transaction.</summary>
    /// <param name="Argument">Foundation request and response.</param>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        Request: JsonObject;
    begin
        Argument.AssertIsLicensed();
        Argument.AssertVersion1();
        if not HasWriteGrant() then begin
            Argument.RespondWithError("Bifrost Error Code ori"::PermissionDenied, PermissionErr, '', '', 'BIFROST SustFull ori', PermissionNextTxt);
            exit;
        end;
        Request := Argument.GetRequestJson();
        if not CheckRequest(Argument, Request) then
            exit;
        if Argument."Omit Commit" then
            Codeunit.Run(Codeunit::"Sust Goal Set Impl ori", Argument)
        else
            if not Codeunit.Run(Codeunit::"Sust Goal Set Impl ori", Argument) then
                Argument.RespondWithLastError();
    end;

    local procedure HasWriteGrant(): Boolean
    var
        AccessMarker: Record "Sust Goal Set Access ori";
    begin
        exit(AccessMarker.WritePermission());
    end;

    local procedure CheckRequest(var Argument: Record "Message Argument ori"; Request: JsonObject): Boolean
    var
        Goals: JsonArray;
        GoalToken: JsonToken;
        ValueToken: JsonToken;
        KeyName: Text;
        ScorecardNoText: Text;
        Index: Integer;
    begin
        foreach KeyName in Request.Keys() do
            if not (KeyName in ['scorecardNo', 'name', 'owner', 'goals']) then
                exit(RefuseUnknownKey(Argument, KeyName));
        if not Request.Get('scorecardNo', ValueToken) then begin
            Argument.RespondWithError("Bifrost Error Code ori"::MissingParameter, MissingScorecardErr, 'scorecardNo', '', ExpectedScorecardTxt, FixScorecardTxt);
            exit(false);
        end;
        if not TryText(ValueToken, 20, ScorecardNoText) or (ScorecardNoText = '') then begin
            Argument.RespondWithError("Bifrost Error Code ori"::MissingParameter, MissingScorecardErr, 'scorecardNo', '', ExpectedScorecardTxt, FixScorecardTxt);
            exit(false);
        end;
        if not CheckTextKey(Argument, Request, 'name', '', 100) then
            exit(false);
        if not CheckTextKey(Argument, Request, 'owner', '', 50) then
            exit(false);
        if not Request.Get('goals', ValueToken) then
            exit(true);
        if not ValueToken.IsArray() then
            exit(RefuseValue(Argument, 'goals'));
        Goals := ValueToken.AsArray();
        for Index := 0 to Goals.Count() - 1 do begin
            Goals.Get(Index, GoalToken);
            if not GoalToken.IsObject() then
                exit(RefuseValue(Argument, StrSubstNo(GoalPathTok, Index)));
            if not CheckGoal(Argument, CopyStr(UpperCase(ScorecardNoText), 1, 20), GoalToken.AsObject(), StrSubstNo(GoalPathTok, Index) + '.') then
                exit(false);
        end;
        exit(true);
    end;

    local procedure CheckGoal(var Argument: Record "Message Argument ori"; ScorecardNo: Code[20]; GoalJson: JsonObject; Prefix: Text): Boolean
    var
        Goal: Record "Sustainability Goal";
        ValueToken: JsonToken;
        KeyName: Text;
        GoalNoText: Text;
        DecimalValue: Decimal;
        IntegerValue: Integer;
        BooleanValue: Boolean;
        StartDate: Date;
        EndDate: Date;
        BaselineStartDate: Date;
        BaselineEndDate: Date;
    begin
        foreach KeyName in GoalJson.Keys() do
            if not IsGoalKey(KeyName) then
                exit(RefuseUnknownKey(Argument, Prefix + KeyName));
        if not GoalJson.Get('no', ValueToken) then begin
            Argument.RespondWithError("Bifrost Error Code ori"::MissingParameter, MissingGoalNoErr, Prefix + 'no', '', ExpectedScorecardTxt, FixValueTxt);
            exit(false);
        end;
        if not TryText(ValueToken, 20, GoalNoText) or (GoalNoText = '') then begin
            Argument.RespondWithError("Bifrost Error Code ori"::MissingParameter, MissingGoalNoErr, Prefix + 'no', '', ExpectedScorecardTxt, FixValueTxt);
            exit(false);
        end;
        if GoalJson.Get('lineNo', ValueToken) then
            if not TryInteger(ValueToken, IntegerValue) then
                exit(RefuseValue(Argument, Prefix + 'lineNo'));
        if not CheckTextKey(Argument, GoalJson, 'name', Prefix, 100) then
            exit(false);
        if not CheckTextKey(Argument, GoalJson, 'owner', Prefix, 50) then
            exit(false);
        if not CheckTextKey(Argument, GoalJson, 'unitOfMeasure', Prefix, 10) then
            exit(false);
        if not CheckTextKey(Argument, GoalJson, 'countryRegionCode', Prefix, 10) then
            exit(false);
        if not CheckTextKey(Argument, GoalJson, 'responsibilityCenter', Prefix, 10) then
            exit(false);
        foreach KeyName in DecimalKeys() do
            if GoalJson.Get(KeyName, ValueToken) then
                if not TryDecimal(ValueToken, DecimalValue) then
                    exit(RefuseValue(Argument, Prefix + KeyName));
        if GoalJson.Get('mainGoal', ValueToken) then
            if not TryBoolean(ValueToken, BooleanValue) then
                exit(RefuseValue(Argument, Prefix + 'mainGoal'));

        // The period rule is checked on the final values: request values over the stored goal.
        if FindGoal(ScorecardNo, GoalJson, Goal) then begin
            StartDate := Goal."Start Date";
            EndDate := Goal."End Date";
            BaselineStartDate := Goal."Baseline Start Date";
            BaselineEndDate := Goal."Baseline End Date";
        end;
        if not ReadDateKey(GoalJson, 'startDate', StartDate) then
            exit(RefuseValue(Argument, Prefix + 'startDate'));
        if not ReadDateKey(GoalJson, 'endDate', EndDate) then
            exit(RefuseValue(Argument, Prefix + 'endDate'));
        if not ReadDateKey(GoalJson, 'baselineStartDate', BaselineStartDate) then
            exit(RefuseValue(Argument, Prefix + 'baselineStartDate'));
        if not ReadDateKey(GoalJson, 'baselineEndDate', BaselineEndDate) then
            exit(RefuseValue(Argument, Prefix + 'baselineEndDate'));
        if (StartDate <> 0D) and (EndDate <> 0D) and (EndDate < StartDate) then
            exit(RefusePeriod(Argument, Prefix + 'endDate', StrSubstNo(EndBeforeStartTxt, GoalNoText)));
        if (BaselineStartDate <> 0D) and (BaselineEndDate <> 0D) and (BaselineEndDate < BaselineStartDate) then
            exit(RefusePeriod(Argument, Prefix + 'baselineEndDate', StrSubstNo(BaselineEndBeforeStartTxt, GoalNoText)));
        if StartDate <> 0D then
            if ((BaselineEndDate <> 0D) and (BaselineEndDate >= StartDate)) or ((BaselineStartDate <> 0D) and (BaselineStartDate >= StartDate)) then
                exit(RefusePeriod(Argument, Prefix + 'baselineEndDate', StrSubstNo(BaselineNotBeforeGoalTxt, GoalNoText)));
        exit(true);
    end;

    local procedure IsGoalKey(KeyName: Text): Boolean
    begin
        if KeyName in ['no', 'lineNo', 'name', 'owner', 'startDate', 'endDate', 'baselineStartDate', 'baselineEndDate', 'unitOfMeasure', 'mainGoal', 'countryRegionCode', 'responsibilityCenter'] then
            exit(true);
        exit(DecimalKeys().Contains(KeyName));
    end;

    local procedure DecimalKeys() Keys: List of [Text]
    begin
        Keys.Add('targetCO2');
        Keys.Add('targetCH4');
        Keys.Add('targetN2O');
        Keys.Add('targetWaterIntensity');
        Keys.Add('targetWasteIntensity');
    end;

    local procedure CheckTextKey(var Argument: Record "Message Argument ori"; Json: JsonObject; KeyName: Text; Prefix: Text; MaxLength: Integer): Boolean
    var
        ValueToken: JsonToken;
        Value: Text;
    begin
        if not Json.Get(KeyName, ValueToken) then
            exit(true);
        if TryText(ValueToken, MaxLength, Value) then
            exit(true);
        exit(RefuseValue(Argument, Prefix + KeyName));
    end;

    local procedure RefuseUnknownKey(var Argument: Record "Message Argument ori"; KeyName: Text): Boolean
    begin
        Argument.RespondWithError("Bifrost Error Code ori"::UnknownParameter, StrSubstNo(UnknownKeyErr, KeyName), KeyName, '', 'scorecardNo, name, owner, goals', FixKeyTxt);
        exit(false);
    end;

    local procedure RefuseValue(var Argument: Record "Message Argument ori"; KeyName: Text): Boolean
    begin
        Argument.RespondWithError("Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidValueErr, KeyName), KeyName, '', '', FixValueTxt);
        exit(false);
    end;

    local procedure RefusePeriod(var Argument: Record "Message Argument ori"; KeyName: Text; Reason: Text): Boolean
    begin
        Argument.RespondWithError("Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidPeriodErr, Reason), KeyName, '', ExpectedPeriodTxt, FixPeriodTxt);
        exit(false);
    end;

    local procedure TryText(Token: JsonToken; MaxLength: Integer; var Value: Text): Boolean
    begin
        if not Token.IsValue() then
            exit(false);
        if Token.AsValue().IsNull() or Token.AsValue().IsUndefined() then
            exit(false);
        Value := Token.AsValue().AsText();
        exit(StrLen(Value) <= MaxLength);
    end;

    [TryFunction]
    local procedure TryDecimal(Token: JsonToken; var Value: Decimal)
    begin
        Value := Token.AsValue().AsDecimal();
    end;

    [TryFunction]
    local procedure TryInteger(Token: JsonToken; var Value: Integer)
    begin
        Value := Token.AsValue().AsInteger();
    end;

    [TryFunction]
    local procedure TryBoolean(Token: JsonToken; var Value: Boolean)
    begin
        Value := Token.AsValue().AsBoolean();
    end;

    /// <summary>Reads an optional date key; keeps Value when the key is absent and accepts null or "" as a blank date.</summary>
    local procedure ReadDateKey(Json: JsonObject; KeyName: Text; var Value: Date): Boolean
    var
        ValueToken: JsonToken;
        DateText: Text;
    begin
        if not Json.Get(KeyName, ValueToken) then
            exit(true);
        if not ValueToken.IsValue() then
            exit(false);
        if ValueToken.AsValue().IsNull() then begin
            Value := 0D;
            exit(true);
        end;
        DateText := ValueToken.AsValue().AsText();
        if DateText = '' then begin
            Value := 0D;
            exit(true);
        end;
        exit(Evaluate(Value, DateText, 9));
    end;

    local procedure FindGoal(ScorecardNo: Code[20]; GoalJson: JsonObject; var Goal: Record "Sustainability Goal"): Boolean
    var
        ValueToken: JsonToken;
    begin
        Goal.SetRange("Scorecard No.", ScorecardNo);
        Goal.SetRange("No.", CopyStr(UpperCase(GoalJson.GetText('no')), 1, MaxStrLen(Goal."No.")));
        if GoalJson.Get('lineNo', ValueToken) then
            Goal.SetRange("Line No.", ValueToken.AsValue().AsInteger());
        exit(Goal.FindFirst());
    end;

    /// <summary>Writes the scorecard and the listed goals. Commits are refused so an error leaves no partial data.</summary>
    [CommitBehavior(CommitBehavior::Error)]
    local procedure Apply(ScorecardNo: Code[20]; Request: JsonObject)
    var
        Scorecard: Record "Sustainability Scorecard";
        GoalToken: JsonToken;
        ValueToken: JsonToken;
    begin
        if not Scorecard.Get(ScorecardNo) then begin
            Scorecard.Init();
            Scorecard."No." := ScorecardNo;
            Scorecard.Insert(true);
        end;
        if Request.Get('name', ValueToken) then
            Scorecard.Validate(Name, CopyStr(ValueToken.AsValue().AsText(), 1, MaxStrLen(Scorecard.Name)));
        if Request.Get('owner', ValueToken) then
            Scorecard.Validate(Owner, CopyStr(ValueToken.AsValue().AsText(), 1, MaxStrLen(Scorecard.Owner)));
        Scorecard.Modify(true);
        if Request.Get('goals', ValueToken) then
            foreach GoalToken in ValueToken.AsArray() do
                ApplyGoal(ScorecardNo, GoalToken.AsObject());
    end;

    local procedure ApplyGoal(ScorecardNo: Code[20]; GoalJson: JsonObject)
    var
        Goal: Record "Sustainability Goal";
        ValueToken: JsonToken;
        StartDate: Date;
        EndDate: Date;
        BaselineStartDate: Date;
        BaselineEndDate: Date;
        MainGoal: Boolean;
    begin
        if not FindGoal(ScorecardNo, GoalJson, Goal) then
            InsertGoal(ScorecardNo, GoalJson, Goal);
        if GoalJson.Get('name', ValueToken) then
            Goal.Validate(Name, CopyStr(ValueToken.AsValue().AsText(), 1, MaxStrLen(Goal.Name)));
        if GoalJson.Get('owner', ValueToken) then
            Goal.Validate(Owner, CopyStr(ValueToken.AsValue().AsText(), 1, MaxStrLen(Goal.Owner)));
        if GoalJson.Get('countryRegionCode', ValueToken) then
            Goal.Validate("Country/Region Code", CopyStr(ValueToken.AsValue().AsText(), 1, MaxStrLen(Goal."Country/Region Code")));
        if GoalJson.Get('responsibilityCenter', ValueToken) then
            Goal.Validate("Responsibility Center", CopyStr(ValueToken.AsValue().AsText(), 1, MaxStrLen(Goal."Responsibility Center")));
        if GoalJson.Get('unitOfMeasure', ValueToken) then
            Goal.Validate("Unit of Measure", CopyStr(ValueToken.AsValue().AsText(), 1, MaxStrLen(Goal."Unit of Measure")));
        if GoalJson.Get('targetCO2', ValueToken) then
            Goal.Validate("Target Value for CO2", ValueToken.AsValue().AsDecimal());
        if GoalJson.Get('targetCH4', ValueToken) then
            Goal.Validate("Target Value for CH4", ValueToken.AsValue().AsDecimal());
        if GoalJson.Get('targetN2O', ValueToken) then
            Goal.Validate("Target Value for N2O", ValueToken.AsValue().AsDecimal());
        if GoalJson.Get('targetWaterIntensity', ValueToken) then
            Goal.Validate("Target Value for Water Int.", ValueToken.AsValue().AsDecimal());
        if GoalJson.Get('targetWasteIntensity', ValueToken) then
            Goal.Validate("Target Value for Waste Int.", ValueToken.AsValue().AsDecimal());
        if GoalJson.Contains('startDate') or GoalJson.Contains('endDate') or GoalJson.Contains('baselineStartDate') or GoalJson.Contains('baselineEndDate') then begin
            StartDate := Goal."Start Date";
            EndDate := Goal."End Date";
            BaselineStartDate := Goal."Baseline Start Date";
            BaselineEndDate := Goal."Baseline End Date";
            ReadDateKey(GoalJson, 'startDate', StartDate);
            ReadDateKey(GoalJson, 'endDate', EndDate);
            ReadDateKey(GoalJson, 'baselineStartDate', BaselineStartDate);
            ReadDateKey(GoalJson, 'baselineEndDate', BaselineEndDate);
            // Clear the stored periods first so the standard cross-checks compare only the final values.
            Goal."Start Date" := 0D;
            Goal."End Date" := 0D;
            Goal."Baseline End Date" := 0D;
            Goal.Validate("Baseline Start Date", BaselineStartDate);
            Goal.Validate("Baseline End Date", BaselineEndDate);
            Goal.Validate("Start Date", StartDate);
            Goal.Validate("End Date", EndDate);
        end;
        if GoalJson.Get('mainGoal', ValueToken) then begin
            MainGoal := ValueToken.AsValue().AsBoolean();
            // The standard check looks at every main goal, this one included, so only a change is validated.
            if MainGoal <> Goal."Main Goal" then
                Goal.Validate("Main Goal", MainGoal);
        end;
        Goal.Modify(true);
    end;

    local procedure InsertGoal(ScorecardNo: Code[20]; GoalJson: JsonObject; var Goal: Record "Sustainability Goal")
    var
        LastGoal: Record "Sustainability Goal";
        ValueToken: JsonToken;
        LineNo: Integer;
    begin
        if GoalJson.Get('lineNo', ValueToken) then
            LineNo := ValueToken.AsValue().AsInteger()
        else begin
            LastGoal.SetRange("Scorecard No.", ScorecardNo);
            LastGoal.SetLoadFields("Line No.");
            LastGoal.SetCurrentKey("Scorecard No.", "No.", "Line No.");
            LineNo := 10000;
            if LastGoal.FindSet() then
                repeat
                    if LastGoal."Line No." >= LineNo then
                        LineNo := LastGoal."Line No." + 10000;
                until LastGoal.Next() = 0;
        end;
        Goal.Init();
        Goal."Scorecard No." := ScorecardNo;
        Goal.Validate("No.", CopyStr(UpperCase(GoalJson.GetText('no')), 1, MaxStrLen(Goal."No.")));
        Goal."Line No." := LineNo;
        Goal.Insert(true);
    end;

    local procedure RespondWithScorecard(var Argument: Record "Message Argument ori"; ScorecardNo: Code[20])
    var
        Scorecard: Record "Sustainability Scorecard";
        Goal: Record "Sustainability Goal";
        Response: JsonObject;
        Result: JsonObject;
        Results: JsonArray;
        GoalJson: JsonObject;
        Goals: JsonArray;
    begin
        Scorecard.Get(ScorecardNo);
        Result.Add('scorecardNo', Scorecard."No.");
        Result.Add('name', Scorecard.Name);
        Result.Add('owner', Scorecard.Owner);
        Goal.SetRange("Scorecard No.", ScorecardNo);
        if Goal.FindSet() then
            repeat
                Clear(GoalJson);
                GoalJson.Add('no', Goal."No.");
                GoalJson.Add('lineNo', Goal."Line No.");
                GoalJson.Add('name', Goal.Name);
                GoalJson.Add('owner', Goal.Owner);
                GoalJson.Add('countryRegionCode', Goal."Country/Region Code");
                GoalJson.Add('responsibilityCenter', Goal."Responsibility Center");
                GoalJson.Add('startDate', FormatDate(Goal."Start Date"));
                GoalJson.Add('endDate', FormatDate(Goal."End Date"));
                GoalJson.Add('baselineStartDate', FormatDate(Goal."Baseline Start Date"));
                GoalJson.Add('baselineEndDate', FormatDate(Goal."Baseline End Date"));
                GoalJson.Add('unitOfMeasure', Goal."Unit of Measure");
                GoalJson.Add('targetCO2', Goal."Target Value for CO2");
                GoalJson.Add('targetCH4', Goal."Target Value for CH4");
                GoalJson.Add('targetN2O', Goal."Target Value for N2O");
                GoalJson.Add('targetWaterIntensity', Goal."Target Value for Water Int.");
                GoalJson.Add('targetWasteIntensity', Goal."Target Value for Waste Int.");
                GoalJson.Add('mainGoal', Goal."Main Goal");
                Goals.Add(GoalJson);
            until Goal.Next() = 0;
        Result.Add('goals', Goals);
        Results.Add(Result);
        Response.Add('status', 'Success');
        Response.Add('noOfRecords', 1);
        Response.Add('result', Results);
        Argument.SetResponseJson(Response);
        Argument."Content Type" := Argument.GetContentTypeJson();
    end;

    local procedure FormatDate(Value: Date): Text
    begin
        if Value = 0D then
            exit('');
        exit(Format(Value, 0, 9));
    end;

    /// <summary>Declares the request envelope.</summary>
    /// <param name="Envelope">Envelope chapter.</param>
    /// <returns>True when the chapter is written.</returns>
    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Subject: JsonObject;
    begin
        Subject.Add('use', 'notUsed');
        Subject.Add('description', 'Use data.scorecardNo.');
        Envelope.Add('subject', Subject);
        Envelope.Add('dataRequired', true);
        Envelope.Add('version', '1.0');
        Envelope.Add('contentType', 'application/json');
        exit(true);
    end;

    /// <summary>Documents the scorecard and goal identity.</summary>
    /// <param name="Target">Target chapter.</param>
    /// <returns>True when the chapter is written.</returns>
    procedure GetTarget(var Target: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Target.Add(Contract.TargetEntry('data.scorecardNo', 'Code[20]', 'No. of the Sustainability Scorecard to create or update.'));
        Target.Add(Contract.TargetEntry('data.goals', 'array', 'Sustainability Goal rows of that scorecard, identified by no and optional lineNo.'));
        exit(true);
    end;

    /// <summary>Lists every accepted request key.</summary>
    /// <param name="Parameters">Parameter chapter.</param>
    /// <returns>True when the chapter is written.</returns>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(Contract.Parameter('scorecardNo', 'string', true, 'Scorecard No., at most 20 characters. The scorecard is created when it does not exist.'));
        Parameters.Add(Contract.Parameter('name', 'string', false, 'Scorecard name, at most 100 characters.'));
        Parameters.Add(Contract.Parameter('owner', 'string', false, 'Scorecard owner: a User Setup user id marked Sustainability Manager, at most 50 characters.'));
        Parameters.Add(Contract.Parameter('goals', 'array', false, 'Goals to create or update. Each object takes no (required, at most 20 characters), lineNo (integer; when omitted the first goal with that no is updated, or a new line is added), name, owner, countryRegionCode, responsibilityCenter, startDate, endDate, baselineStartDate, baselineEndDate (YYYY-MM-DD, null or "" clears), unitOfMeasure, targetCO2, targetCH4, targetN2O, targetWaterIntensity, targetWasteIntensity (numbers) and mainGoal (boolean). Goals not listed are left as they are. Unknown keys are refused before anything is written.'));
        exit(true);
    end;

    /// <summary>Describes the success payload.</summary>
    /// <param name="Response">Response chapter.</param>
    /// <returns>True when the chapter is written.</returns>
    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
        Fields: JsonArray;
    begin
        Fields.Add(Contract.ResponseField('status', 'string', 'Success'));
        Fields.Add(Contract.ResponseField('noOfRecords', 'integer', 'Always 1 on success.'));
        Fields.Add(Contract.ResponseField('result', 'array', 'One scorecard with scorecardNo, name, owner and goals: every goal of the scorecard with no, lineNo, name, owner, countryRegionCode, responsibilityCenter, startDate, endDate, baselineStartDate, baselineEndDate, unitOfMeasure, the five target values and mainGoal. Calculated baseline and current values are not returned.'));
        Response.Add('contentType', 'application/json');
        Response.Add('fields', Fields);
        exit(true);
    end;

    /// <summary>Documents validation, access and Business Central refusals.</summary>
    /// <param name="Errors">Error chapter.</param>
    /// <returns>True when the chapter is written.</returns>
    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::MissingParameter, 'scorecardNo, or the no of a goal, is missing or blank.', 'Send scorecardNo and a no on every goal.'));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::UnknownParameter, 'A key that the contract does not list was sent, at the top level or in a goal.', 'Remove or correct the key.'));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::InvalidParameter, 'A value has the wrong type or is too long, or the period is invalid (the message starts with InvalidPeriod): endDate before startDate, baselineEndDate before baselineStartDate, or a baseline period that does not end before the goal period starts.', 'Correct the value or the dates.'));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, 'The caller does not have BIFROST SustFull ori.', 'Ask an administrator for the Bifrost Sustainability Full role.'));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::BusinessCentralError, 'Business Central refused a value, for example an owner that is not a User Setup user marked Sustainability Manager, a second main goal, a start date without baseline dates, an unknown unit of measure, or a missing Sustainability Setup. The translated Business Central message is returned and nothing is changed.', 'Correct the value named in the message and send the request again.'));
        exit(true);
    end;

    /// <summary>Documents the write, including the absence of Commit and of postings.</summary>
    /// <param name="Effect">Effect chapter.</param>
    /// <returns>True when the chapter is written.</returns>
    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Preconditions: JsonArray;
    begin
        Preconditions.Add('The caller has BIFROST SustFull ori (included in Bifrost Full).');
        Preconditions.Add('A Sustainability Setup record exists before a new goal is added; Business Central takes the goal unit of measure from it.');
        Preconditions.Add('Microsoft Sustainability data rights: the user also needs the Sustainability Admin role (or SUPER), which grants insert and modify on Sustainability Scorecard and Sustainability Goal. BIFROST SustFull ori grants only this type and its permission marker.');
        Preconditions.Add('An owner must be a User Setup user marked Sustainability Manager.');
        Effect.Add('effect', 'write');
        Effect.Add('changes', 'Inserts the Sustainability Scorecard when it does not exist and validates name and owner. For each listed goal, finds it by no (and lineNo when sent) or inserts it with Insert(true), validates every sent field with the standard table rules (the dates in the order baseline start, baseline end, start, end; mainGoal only when it changes) and saves it with Modify(true). Goals not listed are not changed. No sustainability ledger entry is posted. There is no Commit on this path; commits from subscribers are refused. A refusal rolls everything back, so no partial scorecard or goal remains; in omit-commit mode the caller owns the rollback.');
        Effect.Add('idempotent', true);
        Effect.Add('permissionSet', 'BIFROST SustFull ori');
        Effect.Add('preconditions', Preconditions);
        exit(true);
    end;

    /// <summary>No additional app metering.</summary>
    /// <param name="Metering">Unused metering chapter.</param>
    /// <returns>False. This type adds no metering chapter.</returns>
    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        Clear(Metering);
        exit(false);
    end;

    /// <summary>No related operation is required.</summary>
    /// <param name="Related">Unused related chapter.</param>
    /// <returns>False. This type adds no related chapter.</returns>
    procedure GetRelated(var Related: JsonArray): Boolean
    begin
        Clear(Related);
        exit(false);
    end;

    /// <summary>No extra workflow chapter.</summary>
    /// <param name="Workflow">Unused workflow chapter.</param>
    /// <returns>False. This type adds no workflow chapter.</returns>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        Clear(Workflow);
        exit(false);
    end;

    /// <summary>Provides executable request shapes with demo data.</summary>
    /// <param name="Examples">Example chapter.</param>
    /// <returns>True when the chapter is written.</returns>
    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Examples.Add(Contract.Example('Create a scorecard with one main goal', '{"type":"Sustainability.Goal.Set","data":{"scorecardNo":"SC-2030","name":"Net zero 2030","goals":[{"no":"G-CO2","name":"Cut CO2 by half","baselineStartDate":"2024-01-01","baselineEndDate":"2024-12-31","startDate":"2030-01-01","endDate":"2030-12-31","targetCO2":500,"mainGoal":true}]}}', '{"status":"Success","noOfRecords":1,"result":[{"scorecardNo":"SC-2030","name":"Net zero 2030","owner":"","goals":[{"no":"G-CO2","lineNo":10000,"name":"Cut CO2 by half","owner":"","countryRegionCode":"","responsibilityCenter":"","startDate":"2030-01-01","endDate":"2030-12-31","baselineStartDate":"2024-01-01","baselineEndDate":"2024-12-31","unitOfMeasure":"KG","targetCO2":500,"targetCH4":0,"targetN2O":0,"targetWaterIntensity":0,"targetWasteIntensity":0,"mainGoal":true}]}]}'));
        Examples.Add(Contract.Example('Change the target of an existing goal', '{"type":"Sustainability.Goal.Set","data":{"scorecardNo":"SC-2030","goals":[{"no":"G-CO2","targetCO2":450}]}}', '{"status":"Success","noOfRecords":1,"result":[{"scorecardNo":"SC-2030","goals":[{"no":"G-CO2","targetCO2":450}]}]}'));
        exit(true);
    end;

    /// <summary>Provides the help overview.</summary>
    /// <param name="Overview">Overview text.</param>
    /// <returns>True when the chapter is written.</returns>
    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := GetDescription();
        exit(true);
    end;

    /// <summary>Explains effect, idempotency and transaction behaviour.</summary>
    /// <param name="Notes">Notes text.</param>
    /// <returns>True when the chapter is written.</returns>
    procedure GetNotes(var Notes: Text): Boolean
    var
        NotesLbl: Label 'Effect: the scorecard and the listed goals are created or updated with the standard table rules; goals that are not listed stay as they are. Idempotent: the same request again changes nothing. Nothing is posted and there is no Commit on this path. A refusal rolls back the whole request. In omit-commit mode the caller owns the rollback.', Comment = 'is-IS=Áhrif: skorkortið og markmiðin sem talin eru upp eru stofnuð eða uppfærð með stöðluðum töflureglum; markmið sem ekki eru talin upp haldast óbreytt. Ídempotent: sama beiðni aftur breytir engu. Ekkert er bókað og ekkert Commit er á þessari leið. Höfnun bakfærir alla beiðnina. Í ham án staðfestingar ber kallandi ábyrgð á bakfærslu.';
    begin
        Notes := NotesLbl;
        exit(true);
    end;
}
