namespace Origo.Bifrost.Sustainability;

using Microsoft.Sustainability.Ledger;
using Microsoft.Sustainability.Scorecard;
using Origo.Bifrost;

/// <summary>
/// Sustainability.Scorecard.Get. Reads a sustainability scorecard and its goals.
/// Baseline and current values come from Business Central flowfields, after the request
/// periods (or the goal's own periods) are applied as flowfilters. Nothing is posted.
/// </summary>
codeunit 70009209 "Sust Scorecard Get Impl ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;
    TableNo = "Message Argument ori";

    var
        DescriptionLbl: Label 'Returns a sustainability scorecard with each goal''s baseline, current value, target and progress.', MaxLength = 250, Comment = 'is-IS=Skilar sjálfbærnimælaborði með grunnlínu, núverandi gildi, markgildi og framvindu hvers markmiðs.';
        KeywordsLbl: Label 'sustainability scorecard, sustainability goal, scorecard, goal, progress, baseline, target, CO2, emissions, on track', Comment = 'is-IS=sjálfbærnimælaborð, sjálfbærnimarkmið, mælaborð, markmið, framvinda, grunnlína, markgildi, CO2, losun, á réttri leið';
        SelectionLbl: Label 'Reads one scorecard and the progress of its goals. It does not change goals and it does not post.', Comment = 'is-IS=Les eitt mælaborð og framvindu markmiða þess. Það breytir ekki markmiðum og bókar ekki.';
        MissingScorecardErr: Label 'The request is missing the required parameter ''scorecardNo''.', Comment = 'is-IS=Beiðnina vantar nauðsynlega færibreytu ''scorecardNo''.';
        MissingScorecardWhenLbl: Label 'scorecardNo is missing, null or blank.', Comment = 'is-IS=scorecardNo vantar, er null eða autt.';
        MissingScorecardFixLbl: Label 'Send scorecardNo with the scorecard number.', Comment = 'is-IS=Sendu scorecardNo með númeri mælaborðsins.';
        ScorecardNotFoundErr: Label 'Sustainability scorecard ''%1'' does not exist.', Comment = '%1 = scorecard no.||is-IS=Sjálfbærnimælaborðið ''%1'' er ekki til.';
        ScorecardNotFoundWhenLbl: Label 'scorecardNo does not match a sustainability scorecard.', Comment = 'is-IS=scorecardNo passar ekki við sjálfbærnimælaborð.';
        ScorecardNotFoundFixLbl: Label 'Send the number of a scorecard that exists in the company.', Comment = 'is-IS=Sendu númer mælaborðs sem er til í fyrirtækinu.';
        GoalNotFoundErr: Label 'Sustainability goal ''%1'' does not exist on scorecard ''%2''.', Comment = '%1 = goal no., %2 = scorecard no.||is-IS=Sjálfbærnimarkmiðið ''%1'' er ekki til á mælaborðinu ''%2''.';
        GoalNotFoundWhenLbl: Label 'goalNo is sent and no goal on the scorecard has that number.', Comment = 'is-IS=goalNo er sent og ekkert markmið á mælaborðinu hefur það númer.';
        GoalNotFoundFixLbl: Label 'Leave goalNo out to read every goal, or send a goal number that exists on the scorecard.', Comment = 'is-IS=Slepptu goalNo til að lesa öll markmið, eða sendu númer markmiðs sem er til á mælaborðinu.';
        InvalidPeriodErr: Label 'The %1 period is invalid because the from-date is after the to-date.', Comment = '%1 = baseline or current||is-IS=Tímabilið %1 er ógilt því upphafsdagur er á eftir lokadegi.';
        InvalidPeriodWhenLbl: Label 'baselineFrom is after baselineTo, or currentFrom is after currentTo.', Comment = 'is-IS=baselineFrom er á eftir baselineTo, eða currentFrom er á eftir currentTo.';
        InvalidPeriodFixLbl: Label 'Send the from-date on or before the to-date, or leave both ends of that period out.', Comment = 'is-IS=Sendu upphafsdag á eða fyrir lokadag, eða slepptu báðum endum tímabilsins.';
        InvalidFormatErr: Label 'The value of %1 has the wrong JSON type or is not a date in the form yyyy-MM-dd.', Comment = '%1 = parameter name||is-IS=Gildi %1 er af rangri JSON-gerð eða er ekki dagsetning á forminu yyyy-MM-dd.';
        InvalidFormatWhenLbl: Label 'scorecardNo or goalNo is not text, a date parameter is not text, or a date is not yyyy-MM-dd.', Comment = 'is-IS=scorecardNo eða goalNo er ekki texti, dagsetning er ekki texti, eða dagsetning er ekki á forminu yyyy-MM-dd.';
        InvalidFormatFixLbl: Label 'Send codes as text and dates as yyyy-MM-dd.', Comment = 'is-IS=Sendu kóða sem texta og dagsetningar sem yyyy-MM-dd.';
        CodeTooLongErr: Label '%1 is longer than %2 characters.', Comment = '%1 = parameter name, %2 = max length||is-IS=%1 er lengra en %2 stafir.';
        CodeTooLongWhenLbl: Label 'scorecardNo or goalNo is longer than 20 characters.', Comment = 'is-IS=scorecardNo eða goalNo er lengra en 20 stafir.';
        CodeTooLongFixLbl: Label 'Send the scorecard or goal number from Business Central, at most 20 characters.', Comment = 'is-IS=Sendu númer mælaborðs eða markmiðs úr Business Central, í mesta lagi 20 stafir.';
        PermissionDeniedErr: Label 'You do not have read permission for sustainability scorecards.', Comment = 'is-IS=Þú hefur ekki lesheimild á sjálfbærnimælaborð.';
        PermissionDeniedWhenLbl: Label 'The caller cannot read sustainability scorecards, goals or ledger entries.', Comment = 'is-IS=Kallandinn getur ekki lesið sjálfbærnimælaborð, markmið eða færslubók.';
        PermissionDeniedFixLbl: Label 'Ask your administrator for the BIFROST SustRead ori permission set, or for BIFROST Read ori.', Comment = 'is-IS=Biddu kerfisstjóra um heimildasamstæðuna BIFROST SustRead ori, eða um BIFROST Read ori.';
        UnknownKeyErr: Label 'Parameter ''%1'' is not declared by this message type. Nothing was read.', Comment = '%1 = parameter name||is-IS=Viðfangið ''%1'' er ekki skilgreint fyrir þessa skilaboðategund. Ekkert var lesið.';
        UnknownKeyWhenLbl: Label 'The request contains a key other than scorecardNo, goalNo, baselineFrom, baselineTo, currentFrom or currentTo.', Comment = 'is-IS=Beiðnin inniheldur annan lykil en scorecardNo, goalNo, baselineFrom, baselineTo, currentFrom eða currentTo.';
        UnknownKeyFixLbl: Label 'Remove the unknown key. The declared parameters are listed by Help.Implementation.Get.', Comment = 'is-IS=Fjarlægðu óþekkta lykilinn. Skilgreind viðföng eru talin upp af Help.Implementation.Get.';
        BaselineTok: Label 'baseline', Comment = 'is-IS=grunnlína';
        CurrentTok: Label 'current', Comment = 'is-IS=núverandi';
        DateExpectedLbl: Label 'a date in the form yyyy-MM-dd', Comment = 'is-IS=dagsetning á forminu yyyy-MM-dd';
        CodeExpectedLbl: Label 'text of at most 20 characters', Comment = 'is-IS=texti sem er í mesta lagi 20 stafir';
        KnownKeysExpectedLbl: Label 'scorecardNo, goalNo, baselineFrom, baselineTo, currentFrom and currentTo', Comment = 'is-IS=scorecardNo, goalNo, baselineFrom, baselineTo, currentFrom og currentTo';
        OverviewLbl: Label 'Reads one sustainability scorecard and its goals so a caller can see whether the company is on track. Baseline and current amounts are the flowfields on the goal. The request periods, when sent, become the flowfilters before those amounts are calculated. When a period is omitted, the goal''s own baseline dates or its start and end date are used. Progress for a measure is how far the current amount has moved from the baseline toward the target. When the target equals the baseline, that progress is null.', Comment = 'is-IS=Les eitt sjálfbærnimælaborð og markmið þess svo kallaandi sjái hvort fyrirtækið er á réttri leið. Grunnlína og núverandi upphæðir eru flæðisreitir markmiðsins. Tímabil beiðninnar, þegar þau eru send, verða flæðisíur áður en upphæðirnar eru reiknaðar. Þegar tímabili er sleppt eru eigin grunnlínudagsetningar markmiðsins eða upphafs- og lokadagur þess notaðar. Framvinda mælikvarða er hversu langt núverandi upphæð hefur færst frá grunnlínu að markgildi. Þegar markgildið er jafnt grunnlínunni er framvindan null.';
        NotesLbl: Label 'Read only and idempotent. The call does not insert, modify, delete or post, and the number of sustainability ledger entries is unchanged. A hidden type (Sustainability is not configured, or the caller lacks read permission) is left out of the roster; a caller that names the type can still run it when the caller has read permission. Unknown request keys are refused before anything is read. Country and responsibility-center flowfilters follow the goal. An open end of a period (only from, or only to) is a valid open-ended filter.', Comment = 'is-IS=Eingöngu lestur og endurtekið. Kallið bætir hvorki við, breytir, eyðir né bókar, og fjöldi færslna í sjálfbærnifærslubók er óbreyttur. Falinn tegund (sjálfbærni er ekki uppsett, eða kallanda skortir lesheimild) er ekki á listanum; kallaandi sem nefnir tegundina getur samt keyrt hana þegar kallandi hefur lesheimild. Óþekktum lyklum beiðni er hafnað áður en nokkuð er lesið. Flæðisíur lands og ábyrgðarstöðvar fylgja markmiðinu. Opinn endi tímabils (aðeins frá, eða aðeins til) er gild opin sía.';

    /// <summary>
    /// True when Sustainability is configured and the caller may read scorecards, goals and ledger entries.
    /// Hidden is roster-only: a caller that names the type can still run it.
    /// </summary>
    procedure IsEnabled(): Boolean
    var
        Configured: Codeunit "Sust Configured ori";
    begin
        if not HasReadPermission() then
            exit(false);
        exit(Configured.IsConfigured());
    end;

    /// <summary>The scorecard is the record this type reads.</summary>
    procedure GetFilterTableNo(): Integer
    begin
        exit(Database::"Sustainability Scorecard");
    end;

    /// <summary>Short description shown in the message type catalogue.</summary>
    procedure GetDescription(): Text[250]
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>Search words for the catalogue, in the session language.</summary>
    procedure GetKeywords(): Text
    begin
        exit(KeywordsLbl);
    end;

    /// <summary>How to tell this type from a plain table read.</summary>
    procedure GetSelectionDescription(): Text
    begin
        exit(SelectionLbl);
    end;

    /// <summary>The call carries its parameters in data and does not use the envelope subject.</summary>
    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Subject: JsonObject;
    begin
        Subject.Add('use', 'notUsed');
        Subject.Add('description', 'The scorecard number is data.scorecardNo. The envelope subject is not used.');
        Envelope.Add('subject', Subject);
        Envelope.Add('dataRequired', true);
        Envelope.Add('version', '1.0');
        Envelope.Add('contentType', 'application/json');
        exit(true);
    end;

    /// <summary>The scorecard number in data identifies the record.</summary>
    procedure GetTarget(var Target: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Target.Add(ContractMgt.TargetEntry('data.scorecardNo', 'code', 'Sustainability Scorecard number. Required.'));
        exit(true);
    end;

    /// <summary>Request parameters under data.</summary>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('scorecardNo', 'string', true, 'Sustainability scorecard number. Required. At most 20 characters.'));
        Parameters.Add(ContractMgt.Parameter('goalNo', 'string', false, 'When sent, only goals with this number are returned. At most 20 characters. Omit it to return every goal on the scorecard.'));
        Parameters.Add(ContractMgt.Parameter('baselineFrom', 'string', false, 'First date of the baseline flowfilter, yyyy-MM-dd. When both baseline dates are omitted, the goal''s baseline start and end dates are used.'));
        Parameters.Add(ContractMgt.Parameter('baselineTo', 'string', false, 'Last date of the baseline flowfilter, yyyy-MM-dd. Must be on or after baselineFrom when both are sent.'));
        Parameters.Add(ContractMgt.Parameter('currentFrom', 'string', false, 'First date of the current-value flowfilter, yyyy-MM-dd. When both current dates are omitted, the goal''s start and end dates are used.'));
        Parameters.Add(ContractMgt.Parameter('currentTo', 'string', false, 'Last date of the current-value flowfilter, yyyy-MM-dd. Must be on or after currentFrom when both are sent.'));
        exit(true);
    end;

    /// <summary>Success response: the scorecard and one object per goal.</summary>
    procedure GetResponse(var Response: JsonObject): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Fields: JsonArray;
        GoalFields: JsonArray;
        MeasureFields: JsonArray;
        GoalsField: JsonObject;
        MeasureField: JsonObject;
    begin
        Response.Add('contentType', 'application/json');
        Fields.Add(ContractMgt.ResponseField('status', 'string', 'Success.'));
        Fields.Add(ContractMgt.ResponseField('no', 'string', 'Scorecard number.'));
        Fields.Add(ContractMgt.ResponseField('name', 'string', 'Scorecard name.'));
        Fields.Add(ContractMgt.ResponseField('owner', 'string', 'Scorecard owner. Empty when the scorecard has none.'));
        MeasureFields.Add(ContractMgt.ResponseField('co2', 'number', 'CO2 amount, or null in progressPercent when the target equals the baseline.'));
        MeasureFields.Add(ContractMgt.ResponseField('ch4', 'number', 'CH4 amount, or null in progressPercent when the target equals the baseline.'));
        MeasureFields.Add(ContractMgt.ResponseField('n2o', 'number', 'N2O amount, or null in progressPercent when the target equals the baseline.'));
        MeasureFields.Add(ContractMgt.ResponseField('waterIntensity', 'number', 'Water intensity, or null in progressPercent when the target equals the baseline.'));
        MeasureFields.Add(ContractMgt.ResponseField('wasteIntensity', 'number', 'Waste intensity, or null in progressPercent when the target equals the baseline.'));
        GoalFields.Add(ContractMgt.ResponseField('no', 'string', 'Goal number.'));
        GoalFields.Add(ContractMgt.ResponseField('lineNo', 'integer', 'Goal line number. Together with the goal number it identifies the row.'));
        GoalFields.Add(ContractMgt.ResponseField('name', 'string', 'Goal name.'));
        GoalFields.Add(ContractMgt.ResponseField('owner', 'string', 'Goal owner.'));
        GoalFields.Add(ContractMgt.ResponseField('mainGoal', 'boolean', 'True when this row is the main goal.'));
        GoalFields.Add(ContractMgt.ResponseField('startDate', 'string', 'Goal start date, yyyy-MM-dd, or null.'));
        GoalFields.Add(ContractMgt.ResponseField('endDate', 'string', 'Goal end date, yyyy-MM-dd, or null.'));
        MeasureField := ContractMgt.ResponseField('baseline', 'object', 'Baseline amounts for the baseline period.');
        MeasureField.Add('children', MeasureFields);
        GoalFields.Add(MeasureField);
        Clear(MeasureFields);
        MeasureFields.Add(ContractMgt.ResponseField('co2', 'number', 'Current CO2.'));
        MeasureFields.Add(ContractMgt.ResponseField('ch4', 'number', 'Current CH4.'));
        MeasureFields.Add(ContractMgt.ResponseField('n2o', 'number', 'Current N2O.'));
        MeasureFields.Add(ContractMgt.ResponseField('waterIntensity', 'number', 'Current water intensity.'));
        MeasureFields.Add(ContractMgt.ResponseField('wasteIntensity', 'number', 'Current waste intensity.'));
        MeasureField := ContractMgt.ResponseField('current', 'object', 'Current amounts for the current period.');
        MeasureField.Add('children', MeasureFields);
        GoalFields.Add(MeasureField);
        Clear(MeasureFields);
        MeasureFields.Add(ContractMgt.ResponseField('co2', 'number', 'Target CO2.'));
        MeasureFields.Add(ContractMgt.ResponseField('ch4', 'number', 'Target CH4.'));
        MeasureFields.Add(ContractMgt.ResponseField('n2o', 'number', 'Target N2O.'));
        MeasureFields.Add(ContractMgt.ResponseField('waterIntensity', 'number', 'Target water intensity.'));
        MeasureFields.Add(ContractMgt.ResponseField('wasteIntensity', 'number', 'Target waste intensity.'));
        MeasureField := ContractMgt.ResponseField('target', 'object', 'Target amounts stored on the goal.');
        MeasureField.Add('children', MeasureFields);
        GoalFields.Add(MeasureField);
        Clear(MeasureFields);
        MeasureFields.Add(ContractMgt.ResponseField('co2', 'number', 'Progress percent for CO2, or null when the target equals the baseline.'));
        MeasureFields.Add(ContractMgt.ResponseField('ch4', 'number', 'Progress percent for CH4, or null when the target equals the baseline.'));
        MeasureFields.Add(ContractMgt.ResponseField('n2o', 'number', 'Progress percent for N2O, or null when the target equals the baseline.'));
        MeasureFields.Add(ContractMgt.ResponseField('waterIntensity', 'number', 'Progress percent for water intensity, or null when the target equals the baseline.'));
        MeasureFields.Add(ContractMgt.ResponseField('wasteIntensity', 'number', 'Progress percent for waste intensity, or null when the target equals the baseline.'));
        MeasureField := ContractMgt.ResponseField('progressPercent', 'object', 'How far the current amount has moved from the baseline toward the target, in percent. Null for a measure whose target equals its baseline.');
        MeasureField.Add('children', MeasureFields);
        GoalFields.Add(MeasureField);
        GoalsField := ContractMgt.ResponseField('goals', 'array', 'Goals on the scorecard, or the one goal when goalNo is sent.');
        GoalsField.Add('children', GoalFields);
        Fields.Add(GoalsField);
        Response.Add('fields', Fields);
        exit(true);
    end;

    /// <summary>Refusals this type returns. Codes are Foundation error codes.</summary>
    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::MissingParameter, MissingScorecardErr, MissingScorecardWhenLbl, MissingScorecardFixLbl));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::RecordNotFound, ScorecardNotFoundErr, ScorecardNotFoundWhenLbl, ScorecardNotFoundFixLbl));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::RecordNotFound, GoalNotFoundErr, GoalNotFoundWhenLbl, GoalNotFoundFixLbl));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::InvalidParameter, InvalidPeriodErr, InvalidPeriodWhenLbl, InvalidPeriodFixLbl));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::InvalidParameterFormat, InvalidFormatErr, InvalidFormatWhenLbl, InvalidFormatFixLbl));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::InvalidParameter, CodeTooLongErr, CodeTooLongWhenLbl, CodeTooLongFixLbl));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, PermissionDeniedErr, PermissionDeniedWhenLbl, PermissionDeniedFixLbl));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::UnknownParameter, UnknownKeyErr, UnknownKeyWhenLbl, UnknownKeyFixLbl));
        exit(true);
    end;

    /// <summary>Read-only effect. No commit and no sustainability ledger posting.</summary>
    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Preconditions: JsonArray;
    begin
        Preconditions.Add('The caller has read permission on sustainability scorecards, goals and ledger entries (BIFROST SustRead ori).');
        Preconditions.Add('scorecardNo names a sustainability scorecard. goalNo, when sent, names a goal on that scorecard.');
        Preconditions.Add('A period that sends both ends has the from-date on or before the to-date.');
        Effect.Add('effect', 'read');
        Effect.Add('changes', 'Nothing is inserted, modified, deleted or posted. Baseline and current amounts are calculated from sustainability ledger entries that already exist.');
        Effect.Add('idempotent', true);
        Effect.Add('permissionSet', 'BIFROST SustRead ori');
        Effect.Add('preconditions', Preconditions);
        exit(true);
    end;

    /// <summary>This app adds no meter of its own.</summary>
    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        exit(false);
    end;

    /// <summary>A plain table read is the sibling when progress is not needed.</summary>
    procedure GetRelated(var Related: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Related.Add(ContractMgt.RelatedEntry('Data.Records.Get', 'Read the scorecard or goal rows yourself when you do not need baseline, current and progress calculated together.'));
        exit(true);
    end;

    /// <summary>No multi-step workflow. The related chapter names the plain read.</summary>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        exit(false);
    end;

    /// <summary>One example on CRONUS-style demo data.</summary>
    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Example: JsonObject;
        Request: JsonObject;
        Response: JsonObject;
        Goal: JsonObject;
        Goals: JsonArray;
        Baseline: JsonObject;
        Current: JsonObject;
        Target: JsonObject;
        Progress: JsonObject;
        NullValue: JsonValue;
    begin
        Request.Add('scorecardNo', 'SC-CRONUS');
        Request.Add('goalNo', 'CO2');
        Request.Add('baselineFrom', '2024-01-01');
        Request.Add('baselineTo', '2024-01-31');
        Request.Add('currentFrom', '2024-03-01');
        Request.Add('currentTo', '2024-03-31');
        Response.Add('status', 'Success');
        Response.Add('no', 'SC-CRONUS');
        Response.Add('name', 'CRONUS scorecard');
        Response.Add('owner', '');
        Goal.Add('no', 'CO2');
        Goal.Add('lineNo', 10000);
        Goal.Add('name', 'Reduce CO2');
        Goal.Add('owner', '');
        Goal.Add('mainGoal', true);
        Goal.Add('startDate', '2024-03-01');
        Goal.Add('endDate', '2024-03-31');
        Baseline.Add('co2', 100);
        Baseline.Add('ch4', 0);
        Baseline.Add('n2o', 0);
        Baseline.Add('waterIntensity', 0);
        Baseline.Add('wasteIntensity', 0);
        Current.Add('co2', 80);
        Current.Add('ch4', 0);
        Current.Add('n2o', 0);
        Current.Add('waterIntensity', 0);
        Current.Add('wasteIntensity', 0);
        Target.Add('co2', 50);
        Target.Add('ch4', 0);
        Target.Add('n2o', 0);
        Target.Add('waterIntensity', 0);
        Target.Add('wasteIntensity', 0);
        Progress.Add('co2', 40);
        NullValue.SetValueToNull();
        Progress.Add('ch4', NullValue);
        Progress.Add('n2o', NullValue);
        Progress.Add('waterIntensity', NullValue);
        Progress.Add('wasteIntensity', NullValue);
        Goal.Add('baseline', Baseline);
        Goal.Add('current', Current);
        Goal.Add('target', Target);
        Goal.Add('progressPercent', Progress);
        Goals.Add(Goal);
        Response.Add('goals', Goals);
        Example.Add('title', 'Read the CO2 goal on the CRONUS scorecard');
        Example.Add('request', Request);
        Example.Add('response', Response);
        Examples.Add(Example);
        exit(true);
    end;

    /// <summary>What the type does.</summary>
    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := OverviewLbl;
        exit(true);
    end;

    /// <summary>Edge cases a caller should know.</summary>
    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := NotesLbl;
        exit(true);
    end;

    /// <summary>The answer leaves Business Central. The call writes nothing.</summary>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Outbound);
    end;

    /// <summary>Reads the scorecard. OnRun uses the same read so a direct run of the codeunit stays read-only.</summary>
    trigger OnRun()
    begin
        ReadScorecard(Rec);
    end;

    /// <summary>Reads the scorecard into the argument response. Refusals are status Error and leave no data behind.</summary>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        if not HasReadPermission() then begin
            Argument.RespondWithError("Bifrost Error Code ori"::PermissionDenied, PermissionDeniedErr, '', '', 'BIFROST SustRead ori', PermissionDeniedFixLbl);
            exit;
        end;

        Argument.AssertVersion1();
        Argument.AssertIsLicensed();
        ReadScorecard(Argument);
    end;

    local procedure ReadScorecard(var Argument: Record "Message Argument ori")
    var
        SustainabilityScorecard: Record "Sustainability Scorecard";
        RequestJson: JsonObject;
        ScorecardNo: Code[20];
        GoalNo: Code[20];
        BaselineFrom: Date;
        BaselineTo: Date;
        CurrentFrom: Date;
        CurrentTo: Date;
        HasScorecardNo: Boolean;
        HasGoalNo: Boolean;
        HasBaselineFrom: Boolean;
        HasBaselineTo: Boolean;
        HasCurrentFrom: Boolean;
        HasCurrentTo: Boolean;
    begin
        RequestJson := Argument.GetRequestJson();
        if RefuseUnknownKeys(RequestJson, Argument) then
            exit;
        if not TryReadCode(RequestJson, 'scorecardNo', true, Argument, ScorecardNo, HasScorecardNo) then
            exit;
        if not HasScorecardNo then
            exit;
        if ScorecardNo = '' then begin
            Argument.RespondWithError("Bifrost Error Code ori"::MissingParameter, MissingScorecardErr, 'scorecardNo', '', CodeExpectedLbl, MissingScorecardFixLbl);
            exit;
        end;
        if not TryReadCode(RequestJson, 'goalNo', false, Argument, GoalNo, HasGoalNo) then
            exit;
        if not TryReadDate(RequestJson, 'baselineFrom', Argument, BaselineFrom, HasBaselineFrom) then
            exit;
        if not TryReadDate(RequestJson, 'baselineTo', Argument, BaselineTo, HasBaselineTo) then
            exit;
        if not TryReadDate(RequestJson, 'currentFrom', Argument, CurrentFrom, HasCurrentFrom) then
            exit;
        if not TryReadDate(RequestJson, 'currentTo', Argument, CurrentTo, HasCurrentTo) then
            exit;
        if HasBaselineFrom and HasBaselineTo and (BaselineFrom > BaselineTo) then begin
            Argument.RespondWithError("Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidPeriodErr, BaselineTok), 'baselineFrom', Format(BaselineFrom, 0, 9), DateExpectedLbl, InvalidPeriodFixLbl);
            exit;
        end;
        if HasCurrentFrom and HasCurrentTo and (CurrentFrom > CurrentTo) then begin
            Argument.RespondWithError("Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidPeriodErr, CurrentTok), 'currentFrom', Format(CurrentFrom, 0, 9), DateExpectedLbl, InvalidPeriodFixLbl);
            exit;
        end;

        SustainabilityScorecard.SetLoadFields("No.", Name, Owner);
        if not SustainabilityScorecard.Get(ScorecardNo) then begin
            Argument.RespondWithError("Bifrost Error Code ori"::RecordNotFound, StrSubstNo(ScorecardNotFoundErr, ScorecardNo), 'scorecardNo', ScorecardNo, '', ScorecardNotFoundFixLbl);
            exit;
        end;

        WriteResponse(Argument, SustainabilityScorecard, GoalNo, HasGoalNo, BaselineFrom, HasBaselineFrom, BaselineTo, HasBaselineTo, CurrentFrom, HasCurrentFrom, CurrentTo, HasCurrentTo);
    end;

    local procedure WriteResponse(var Argument: Record "Message Argument ori"; SustainabilityScorecard: Record "Sustainability Scorecard"; GoalNo: Code[20]; HasGoalNo: Boolean; BaselineFrom: Date; HasBaselineFrom: Boolean; BaselineTo: Date; HasBaselineTo: Boolean; CurrentFrom: Date; HasCurrentFrom: Boolean; CurrentTo: Date; HasCurrentTo: Boolean)
    var
        SustainabilityGoal: Record "Sustainability Goal";
        ResponseJson: JsonObject;
        Goals: JsonArray;
    begin
        SustainabilityGoal.SetLoadFields("No.", "Line No.", Name, Owner, "Main Goal", "Start Date", "End Date", "Baseline Start Date", "Baseline End Date", "Country/Region Code", "Responsibility Center", "Target Value for CO2", "Target Value for CH4", "Target Value for N2O", "Target Value for Water Int.", "Target Value for Waste Int.");
        SustainabilityGoal.SetRange("Scorecard No.", SustainabilityScorecard."No.");
        if HasGoalNo then
            SustainabilityGoal.SetRange("No.", GoalNo);
        if HasGoalNo and SustainabilityGoal.IsEmpty() then begin
            Argument.RespondWithError("Bifrost Error Code ori"::RecordNotFound, StrSubstNo(GoalNotFoundErr, GoalNo, SustainabilityScorecard."No."), 'goalNo', GoalNo, '', GoalNotFoundFixLbl);
            exit;
        end;

        if SustainabilityGoal.FindSet() then
            repeat
                Goals.Add(GoalJson(SustainabilityGoal, BaselineFrom, HasBaselineFrom, BaselineTo, HasBaselineTo, CurrentFrom, HasCurrentFrom, CurrentTo, HasCurrentTo));
            until SustainabilityGoal.Next() = 0;

        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('no', SustainabilityScorecard."No.");
        ResponseJson.Add('name', SustainabilityScorecard.Name);
        ResponseJson.Add('owner', SustainabilityScorecard.Owner);
        ResponseJson.Add('goals', Goals);
        Argument.SetResponseJson(ResponseJson);
        Argument."Content Type" := Argument.GetContentTypeJson();
    end;

    local procedure GoalJson(var SustainabilityGoal: Record "Sustainability Goal"; BaselineFrom: Date; HasBaselineFrom: Boolean; BaselineTo: Date; HasBaselineTo: Boolean; CurrentFrom: Date; HasCurrentFrom: Boolean; CurrentTo: Date; HasCurrentTo: Boolean) Goal: JsonObject
    var
        Baseline: JsonObject;
        Current: JsonObject;
        Target: JsonObject;
        Progress: JsonObject;
    begin
        ApplyBaselineFilter(SustainabilityGoal, BaselineFrom, HasBaselineFrom, BaselineTo, HasBaselineTo);
        ApplyCurrentFilter(SustainabilityGoal, CurrentFrom, HasCurrentFrom, CurrentTo, HasCurrentTo);
        ApplyGoalFlowFilters(SustainabilityGoal);
        SustainabilityGoal.CalcFields("Baseline for CO2", "Baseline for CH4", "Baseline for N2O", "Baseline for Water Intensity", "Baseline for Waste Intensity", "Current Value for CO2", "Current Value for CH4", "Current Value for N2O", "Current Value for Water Int.", "Current Value for Waste Int.");

        Goal.Add('no', SustainabilityGoal."No.");
        Goal.Add('lineNo', SustainabilityGoal."Line No.");
        Goal.Add('name', SustainabilityGoal.Name);
        Goal.Add('owner', SustainabilityGoal.Owner);
        Goal.Add('mainGoal', SustainabilityGoal."Main Goal");
        AddDate(Goal, 'startDate', SustainabilityGoal."Start Date");
        AddDate(Goal, 'endDate', SustainabilityGoal."End Date");

        Baseline.Add('co2', SustainabilityGoal."Baseline for CO2");
        Baseline.Add('ch4', SustainabilityGoal."Baseline for CH4");
        Baseline.Add('n2o', SustainabilityGoal."Baseline for N2O");
        Baseline.Add('waterIntensity', SustainabilityGoal."Baseline for Water Intensity");
        Baseline.Add('wasteIntensity', SustainabilityGoal."Baseline for Waste Intensity");
        Current.Add('co2', SustainabilityGoal."Current Value for CO2");
        Current.Add('ch4', SustainabilityGoal."Current Value for CH4");
        Current.Add('n2o', SustainabilityGoal."Current Value for N2O");
        Current.Add('waterIntensity', SustainabilityGoal."Current Value for Water Int.");
        Current.Add('wasteIntensity', SustainabilityGoal."Current Value for Waste Int.");
        Target.Add('co2', SustainabilityGoal."Target Value for CO2");
        Target.Add('ch4', SustainabilityGoal."Target Value for CH4");
        Target.Add('n2o', SustainabilityGoal."Target Value for N2O");
        Target.Add('waterIntensity', SustainabilityGoal."Target Value for Water Int.");
        Target.Add('wasteIntensity', SustainabilityGoal."Target Value for Waste Int.");
        AddProgress(Progress, 'co2', SustainabilityGoal."Baseline for CO2", SustainabilityGoal."Current Value for CO2", SustainabilityGoal."Target Value for CO2");
        AddProgress(Progress, 'ch4', SustainabilityGoal."Baseline for CH4", SustainabilityGoal."Current Value for CH4", SustainabilityGoal."Target Value for CH4");
        AddProgress(Progress, 'n2o', SustainabilityGoal."Baseline for N2O", SustainabilityGoal."Current Value for N2O", SustainabilityGoal."Target Value for N2O");
        AddProgress(Progress, 'waterIntensity', SustainabilityGoal."Baseline for Water Intensity", SustainabilityGoal."Current Value for Water Int.", SustainabilityGoal."Target Value for Water Int.");
        AddProgress(Progress, 'wasteIntensity', SustainabilityGoal."Baseline for Waste Intensity", SustainabilityGoal."Current Value for Waste Int.", SustainabilityGoal."Target Value for Waste Int.");
        Goal.Add('baseline', Baseline);
        Goal.Add('current', Current);
        Goal.Add('target', Target);
        Goal.Add('progressPercent', Progress);
    end;

    local procedure ApplyBaselineFilter(var SustainabilityGoal: Record "Sustainability Goal"; FromDate: Date; HasFrom: Boolean; ToDate: Date; HasTo: Boolean)
    var
        StartDate: Date;
        EndDate: Date;
    begin
        if not HasFrom and not HasTo then begin
            StartDate := SustainabilityGoal."Baseline Start Date";
            EndDate := SustainabilityGoal."Baseline End Date";
        end else begin
            if HasFrom then
                StartDate := FromDate;
            if HasTo then
                EndDate := ToDate;
        end;
        SustainabilityGoal.UpdateBaselineDateFilter(StartDate, EndDate);
    end;

    local procedure ApplyCurrentFilter(var SustainabilityGoal: Record "Sustainability Goal"; FromDate: Date; HasFrom: Boolean; ToDate: Date; HasTo: Boolean)
    var
        StartDate: Date;
        EndDate: Date;
    begin
        if not HasFrom and not HasTo then begin
            StartDate := SustainabilityGoal."Start Date";
            EndDate := SustainabilityGoal."End Date";
        end else begin
            if HasFrom then
                StartDate := FromDate;
            if HasTo then
                EndDate := ToDate;
        end;
        SustainabilityGoal.UpdateCurrentDateFilter(StartDate, EndDate);
    end;

    local procedure ApplyGoalFlowFilters(var SustainabilityGoal: Record "Sustainability Goal")
    begin
        if SustainabilityGoal."Country/Region Code" <> '' then
            SustainabilityGoal.SetRange("Country/Region Code Filter", SustainabilityGoal."Country/Region Code");
        if SustainabilityGoal."Responsibility Center" <> '' then
            SustainabilityGoal.SetRange("Responsibility Center Filter", SustainabilityGoal."Responsibility Center");
    end;

    local procedure AddProgress(var Progress: JsonObject; Name: Text; Baseline: Decimal; Current: Decimal; Target: Decimal)
    var
        NullValue: JsonValue;
    begin
        if Target = Baseline then begin
            NullValue.SetValueToNull();
            Progress.Add(Name, NullValue);
            exit;
        end;
        Progress.Add(Name, Round((Baseline - Current) / (Baseline - Target) * 100, 0.01));
    end;

    local procedure AddDate(var Parent: JsonObject; Name: Text; Value: Date)
    var
        NullValue: JsonValue;
    begin
        if Value = 0D then begin
            NullValue.SetValueToNull();
            Parent.Add(Name, NullValue);
        end else
            Parent.Add(Name, Format(Value, 0, 9));
    end;

    local procedure RefuseUnknownKeys(RequestJson: JsonObject; var Argument: Record "Message Argument ori"): Boolean
    var
        Keys: List of [Text];
        KeyName: Text;
    begin
        Keys := RequestJson.Keys();
        foreach KeyName in Keys do
            if not IsKnownKey(KeyName) then begin
                Argument.RespondWithError("Bifrost Error Code ori"::UnknownParameter, StrSubstNo(UnknownKeyErr, KeyName), KeyName, '', KnownKeysExpectedLbl, UnknownKeyFixLbl);
                exit(true);
            end;
    end;

    local procedure IsKnownKey(KeyName: Text): Boolean
    begin
        exit(KeyName in ['scorecardNo', 'goalNo', 'baselineFrom', 'baselineTo', 'currentFrom', 'currentTo']);
    end;

    local procedure TryReadCode(RequestJson: JsonObject; KeyName: Text; Required: Boolean; var Argument: Record "Message Argument ori"; var Value: Code[20]; var HasValue: Boolean): Boolean
    var
        Token: JsonToken;
        TextValue: Text;
    begin
        HasValue := false;
        Value := '';
        if not RequestJson.Get(KeyName, Token) then begin
            if Required then
                Argument.RespondWithError("Bifrost Error Code ori"::MissingParameter, MissingScorecardErr, KeyName, '', CodeExpectedLbl, MissingScorecardFixLbl);
            exit(not Required);
        end;
        if Token.IsValue() and Token.AsValue().IsNull() then begin
            if Required then
                Argument.RespondWithError("Bifrost Error Code ori"::MissingParameter, MissingScorecardErr, KeyName, '', CodeExpectedLbl, MissingScorecardFixLbl);
            exit(not Required);
        end;
        if not Token.IsValue() then begin
            Argument.RespondWithError("Bifrost Error Code ori"::InvalidParameterFormat, StrSubstNo(InvalidFormatErr, KeyName), KeyName, '', CodeExpectedLbl, InvalidFormatFixLbl);
            exit(false);
        end;
        TextValue := Token.AsValue().AsText();
        if TextValue = '' then begin
            if Required then
                Argument.RespondWithError("Bifrost Error Code ori"::MissingParameter, MissingScorecardErr, KeyName, '', CodeExpectedLbl, MissingScorecardFixLbl);
            exit(not Required);
        end;
        if StrLen(TextValue) > MaxStrLen(Value) then begin
            Argument.RespondWithError("Bifrost Error Code ori"::InvalidParameter, StrSubstNo(CodeTooLongErr, KeyName, MaxStrLen(Value)), KeyName, CopyStr(TextValue, 1, 80), CodeExpectedLbl, CodeTooLongFixLbl);
            exit(false);
        end;
        Value := CopyStr(TextValue, 1, MaxStrLen(Value));
        HasValue := true;
        exit(true);
    end;

    local procedure TryReadDate(RequestJson: JsonObject; KeyName: Text; var Argument: Record "Message Argument ori"; var Value: Date; var HasValue: Boolean): Boolean
    var
        Token: JsonToken;
        TextValue: Text;
    begin
        HasValue := false;
        Value := 0D;
        if not RequestJson.Get(KeyName, Token) then
            exit(true);
        if Token.IsValue() and Token.AsValue().IsNull() then
            exit(true);
        if not Token.IsValue() then begin
            Argument.RespondWithError("Bifrost Error Code ori"::InvalidParameterFormat, StrSubstNo(InvalidFormatErr, KeyName), KeyName, '', DateExpectedLbl, InvalidFormatFixLbl);
            exit(false);
        end;
        TextValue := Token.AsValue().AsText();
        if TextValue = '' then
            exit(true);
        if not Evaluate(Value, TextValue, 9) then begin
            Argument.RespondWithError("Bifrost Error Code ori"::InvalidParameterFormat, StrSubstNo(InvalidFormatErr, KeyName), KeyName, CopyStr(TextValue, 1, 80), DateExpectedLbl, InvalidFormatFixLbl);
            exit(false);
        end;
        HasValue := true;
        exit(true);
    end;

    local procedure HasReadPermission(): Boolean
    var
        SustainabilityScorecard: Record "Sustainability Scorecard";
        SustainabilityGoal: Record "Sustainability Goal";
        SustainabilityLedgerEntry: Record "Sustainability Ledger Entry";
    begin
        exit(SustainabilityScorecard.ReadPermission() and SustainabilityGoal.ReadPermission() and SustainabilityLedgerEntry.ReadPermission());
    end;
}
