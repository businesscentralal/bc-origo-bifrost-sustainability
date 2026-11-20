namespace Origo.Bifrost.Sustainability;

using Microsoft.Sustainability.Account;
using Origo.Bifrost;

/// <summary>Atomically maintains a category and the subcategories supplied by the caller.</summary>
codeunit 70009211 "Sust Category Set Impl ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    TableNo = "Message Argument ori";

    var
        DescriptionLbl: Label 'Creates or updates a sustainability account category and its listed subcategories using Microsoft validation. Leaves other subcategories unchanged and posts no ledger entries.', MaxLength = 250, Comment = 'is-IS=Stofnar eða uppfærir sjálfbærnireikningsflokk og tilgreinda undirflokka með sannprófun Microsoft. Aðrir undirflokkar haldast óbreyttir og engar fjárhagsfærslur eru bókaðar.';
        PermissionErr: Label 'Category maintenance requires BIFROST SustFull ori.', Comment = 'is-IS=Viðhald flokka krefst BIFROST SustFull ori.';
        MissingErr: Label 'The required parameter %1 is missing or empty.', Comment = '%1 = parameter name|is-IS=Nauðsynlega færibreytu %1 vantar eða hún er tóm.';
        UnknownErr: Label 'Unknown parameter %1.', Comment = '%1 = parameter name|is-IS=Óþekkt færibreyta %1.';
        InvalidErr: Label 'Invalid parameter %1. Expected %2.', Comment = '%1 = parameter name, %2 = expected value|is-IS=Ógild færibreyta %1. Búist var við %2.';
        FixLbl: Label 'Correct the named parameter and retry; no changes were saved.', Comment = 'is-IS=Leiðréttu tilgreinda færibreytu og reyndu aftur; engar breytingar voru vistaðar.';
        PermissionFixLbl: Label 'Ask an administrator for BIFROST SustFull ori and the Microsoft Sustainability permissions.', Comment = 'is-IS=Biddu stjórnanda um BIFROST SustFull ori og sjálfbærniheimildir Microsoft.';
        TextExpectedLbl: Label 'text of at most %1 characters', Comment = '%1 = maximum length|is-IS=texti með að hámarki %1 stöfum';
        BooleanExpectedLbl: Label 'a JSON boolean', Comment = 'is-IS=JSON-rökgildi';
        NumberExpectedLbl: Label 'a JSON number', Comment = 'is-IS=JSON-tölugildi';
        ArrayExpectedLbl: Label 'an array of subcategory objects', Comment = 'is-IS=fylki af undirflokkshlutum';
        ObjectExpectedLbl: Label 'a subcategory object', Comment = 'is-IS=undirflokkshlutur';
        NotesLbl: Label 'Only code is required. Omitted fields retain stored values; new records use Microsoft defaults. Enum inputs use the invariant Microsoft enum names, not translated captions. Each listed subcategory requires code; omitted subcategories are never deleted. Microsoft validation can recalculate existing sustainability journal lines and refuse changes to categories used by ledger entries. No posting codeunit or external service is called. There is no explicit Commit; normal Codeunit.Run commits the complete successful write and rolls it back on refusal. Omit Commit delegates transaction and rollback ownership to the caller. Explicit subscriber commits are prohibited.', Comment = 'is-IS=Aðeins code er skylda. Slepptri færibreytu er haldið óbreyttri; nýjar færslur nota sjálfgefin gildi Microsoft. Upptalningar nota föst heiti Microsoft en ekki þýdda titla. Hver tilgreindur undirflokkur krefst code; undirflokkum er aldrei eytt. Sannprófun Microsoft getur endurreiknað sjálfbærnibókarlínur og hafnað breytingum á flokkum sem eru notaðir í fjárhagsfærslum. Engin bókunarvinnsla eða ytri þjónusta er kölluð. Ekkert beint Commit er notað; venjulegt Codeunit.Run vistar alla breytinguna þegar hún tekst og bakfærir við höfnun. Með Omit Commit ber kallandi ábyrgð á færslu og bakfærslu. Beinar staðfestingar áskrifenda eru bannaðar.';
        ChangesLbl: Label 'Upserts Sustain. Account Category and listed Sustain. Account Subcategory records through Validate, Insert(true) and Modify(true). Standard validation may recalculate related journal lines. Never deletes a subcategory or posts a ledger entry.', Comment = 'is-IS=Stofnar eða uppfærir sjálfbærnireikningsflokk og tilgreinda undirflokka með Validate, Insert(true) og Modify(true). Stöðluð sannprófun getur endurreiknað tengdar bókarlínur. Eyðir aldrei undirflokki og bókar aldrei fjárhagsfærslu.';
        PreconditionsLbl: Label 'Full role and native Microsoft table permissions; values must satisfy standard Sustainability validation. Configuration controls roster visibility only and does not block a known type.', Comment = 'is-IS=Fullt hlutverk og staðlaðar töfluheimildir Microsoft; gildi verða að standast sjálfbærnisannprófun. Uppsetning stýrir aðeins sýnileika og hindrar ekki kall á þekkta tegund.';
        BusinessWhenLbl: Label 'Microsoft validation rejects the request, including an emission scope change on a category used by posted ledger entries.', Comment = 'is-IS=Sannprófun Microsoft hafnar beiðni, meðal annars breytingu á losunarumfangi flokks sem er notaður í bókuðum færslum.';
        BusinessFixLbl: Label 'Follow the Business Central message; correct the setup or use a new category. No changes were saved.', Comment = 'is-IS=Fylgdu skilaboðum Business Central; leiðréttu uppsetningu eða notaðu nýjan flokk. Engar breytingar voru vistaðar.';
        CodeHelpLbl: Label 'Category code, required text, maximum 20 characters.', Comment = 'is-IS=Flokkskóði, nauðsynlegur texti, að hámarki 20 stafir.';
        ScopeHelpLbl: Label 'Invariant enum name: blank, Scope 1, Scope 2, Scope 3, Water/Waste or Out of Scope. Extensions may add names.', Comment = 'is-IS=Fast upptalningarheiti: bil, Scope 1, Scope 2, Scope 3, Water/Waste eða Out of Scope. Viðbætur geta bætt við heitum.';
        FoundationHelpLbl: Label 'Invariant enum name: blank, Fuel/Electricity, Distance, Installations or Custom.', Comment = 'is-IS=Fast upptalningarheiti: bil, Fuel/Electricity, Distance, Installations eða Custom.';
        SubcategoriesHelpLbl: Label 'Array of objects: required code (20 characters), optional description (100), emissionFactorCO2, emissionFactorCH4, emissionFactorN2O (JSON numbers) and renewableEnergy (JSON boolean). Unknown nested keys are refused. Unlisted subcategories remain unchanged.', Comment = 'is-IS=Fylki hluta: code er skylda (20 stafir), valfrjálst description (100), emissionFactorCO2, emissionFactorCH4, emissionFactorN2O (JSON-tölur) og renewableEnergy (JSON-rökgildi). Óþekktum undirlyklum er hafnað. Ótilgreindir undirflokkar haldast óbreyttir.';
        FlagHelpLbl: Label 'Optional JSON boolean; omitted values are unchanged.', Comment = 'is-IS=Valfrjálst JSON-rökgildi; gildi sem er sleppt helst óbreytt.';
        CategoryResponseLbl: Label 'Category as stored, using the request field names and invariant enum names.', Comment = 'is-IS=Flokkur eins og hann er vistaður með heitum færibreyta og föstum upptalningarheitum.';
        SubcategoryResponseLbl: Label 'All stored subcategories of this category, including those not listed in the request.', Comment = 'is-IS=Allir vistaðir undirflokkar þessa flokks, einnig þeir sem eru ekki tilgreindir í beiðni.';
        SuccessLbl: Label 'Success.', Comment = 'is-IS=Tókst.';
        ExampleLbl: Label 'Maintain a demo fuel category', Comment = 'is-IS=Viðhalda eldsneytisflokki í sýnigögnum';

    trigger OnRun()
    begin
        PerformWrite(Rec);
    end;

    /// <summary>Runs the atomic write and returns Foundation error responses on refusal.</summary>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Argument.AssertVersion1();
        Argument.AssertIsLicensed();
        if Argument."Omit Commit" then begin
            PerformWrite(Argument);
            exit;
        end;
        if not Codeunit.Run(Codeunit::"Sust Category Set Impl ori", Argument) then
            Argument.RespondWithLastError();
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure PerformWrite(var Argument: Record "Message Argument ori")
    var
        AccessCapability: Record "Sust Category Access ori";
        Category: Record "Sustain. Account Category";
        CategoryRef: RecordRef;
        Request: JsonObject;
        Response: JsonObject;
        CategoryJson: JsonObject;
        Subcategories: JsonArray;
        CategoryCode: Code[20];
        IsNew: Boolean;
    begin
        if not AccessCapability.WritePermission() then
            Refuse(Argument, "Bifrost Error Code ori"::PermissionDenied, PermissionErr, 'permissionSet', 'BIFROST SustFull ori');
        Request := Argument.GetRequestJson();
        CheckKeys(Request, false, Argument);
        CategoryCode := CopyStr(ReadText(Request, 'code', 20, true, Argument), 1, 20);
        Category.ReadIsolation := IsolationLevel::UpdLock;
        IsNew := not Category.Get(CategoryCode);
        if IsNew then begin
            Category.Init();
            Category.Validate(Code, CategoryCode);
        end;
        Argument.SetErrorContext('category', PreconditionsLbl, BusinessFixLbl);
        ApplyEnums(Request, Category, Argument);
        CategoryRef.GetTable(Category);
        ApplyCategoryFields(Request, CategoryRef, Argument);
        CategoryRef.SetTable(Category);
        if IsNew then
            Category.Insert(true)
        else
            Category.Modify(true);
        ApplySubcategories(Request, Category.Code, Argument);
        Category.Get(Category.Code);
        CategoryRef.GetTable(Category);
        CategoryJson.Add('code', Category.Code);
        CategoryJson.Add('emissionScope', Enum::"Emission Scope".Names().Get(Enum::"Emission Scope".Ordinals().IndexOf(Category."Emission Scope".AsInteger())));
        CategoryJson.Add('calculationFoundation', Enum::"Calculation Foundation".Names().Get(Enum::"Calculation Foundation".Ordinals().IndexOf(Category."Calculation Foundation".AsInteger())));
        AddCategoryFields(CategoryJson, CategoryRef);
        ReadSubcategories(Category.Code, Subcategories);
        Response.Add('status', 'Success');
        Response.Add('category', CategoryJson);
        Response.Add('subcategories', Subcategories);
        Argument.SetResponseJson(Response);
        Argument."Content Type" := Argument.GetContentTypeJson();
    end;

    local procedure ApplyEnums(Request: JsonObject; var Category: Record "Sustain. Account Category"; var Argument: Record "Message Argument ori")
    var
        EnumNames: List of [Text];
        EnumOrdinals: List of [Integer];
        EnumName: Text;
        EnumIndex: Integer;
    begin
        if Request.Contains('emissionScope') then begin
            EnumName := ReadText(Request, 'emissionScope', 100, false, Argument);
            EnumNames := Enum::"Emission Scope".Names();
            EnumOrdinals := Enum::"Emission Scope".Ordinals();
            EnumIndex := EnumNames.IndexOf(EnumName);
            if EnumIndex = 0 then
                Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidErr, 'emissionScope', JoinNames(EnumNames)), 'emissionScope', JoinNames(EnumNames));
            if Category."Emission Scope".AsInteger() <> EnumOrdinals.Get(EnumIndex) then
                Category.Validate("Emission Scope", Enum::"Emission Scope".FromInteger(EnumOrdinals.Get(EnumIndex)));
        end;
        if Request.Contains('calculationFoundation') then begin
            EnumName := ReadText(Request, 'calculationFoundation', 100, false, Argument);
            EnumNames := Enum::"Calculation Foundation".Names();
            EnumOrdinals := Enum::"Calculation Foundation".Ordinals();
            EnumIndex := EnumNames.IndexOf(EnumName);
            if EnumIndex = 0 then
                Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidErr, 'calculationFoundation', JoinNames(EnumNames)), 'calculationFoundation', JoinNames(EnumNames));
            if Category."Calculation Foundation".AsInteger() <> EnumOrdinals.Get(EnumIndex) then
                Category.Validate("Calculation Foundation", Enum::"Calculation Foundation".FromInteger(EnumOrdinals.Get(EnumIndex)));
        end;
    end;

    local procedure JoinNames(EnumNames: List of [Text]) Result: Text
    var
        EnumName: Text;
    begin
        foreach EnumName in EnumNames do begin
            if Result <> '' then
                Result += ', ';
            Result += '"' + EnumName + '"';
        end;
    end;

    local procedure CheckKeys(Request: JsonObject; IsSubcategory: Boolean; var Argument: Record "Message Argument ori")
    var
        ParameterName: Text;
        Allowed: Boolean;
    begin
        foreach ParameterName in Request.Keys() do begin
            if IsSubcategory then
                Allowed := ParameterName in ['code', 'description', 'emissionFactorCO2', 'emissionFactorCH4', 'emissionFactorN2O', 'renewableEnergy']
            else
                Allowed := ParameterName in ['code', 'emissionScope', 'calculationFoundation', 'subcategories', 'description', 'co2', 'ch4', 'n2o', 'waterIntensity', 'dischargedIntoWater', 'wasteIntensity', 'customValue', 'calculateFromGeneralLedger', 'glAccountFilter', 'globalDimension1Filter', 'globalDimension2Filter'];
            if not Allowed then
                Refuse(Argument, "Bifrost Error Code ori"::UnknownParameter, StrSubstNo(UnknownErr, ParameterName), ParameterName, '');
        end;
    end;

    local procedure ReadText(Request: JsonObject; ParameterName: Text; MaximumLength: Integer; Required: Boolean; var Argument: Record "Message Argument ori") Result: Text
    var
        Token: JsonToken;
        Serialized: Text;
    begin
        if not Request.Get(ParameterName, Token) then
            Refuse(Argument, "Bifrost Error Code ori"::MissingParameter, StrSubstNo(MissingErr, ParameterName), ParameterName, CodeHelpLbl);
        Token.WriteTo(Serialized);
        if CopyStr(Serialized, 1, 1) <> '"' then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidErr, ParameterName, StrSubstNo(TextExpectedLbl, MaximumLength)), ParameterName, StrSubstNo(TextExpectedLbl, MaximumLength));
        Result := Token.AsValue().AsText();
        if Required and (DelChr(Result, '<>', ' ') = '') then
            Refuse(Argument, "Bifrost Error Code ori"::MissingParameter, StrSubstNo(MissingErr, ParameterName), ParameterName, CodeHelpLbl);
        if StrLen(Result) > MaximumLength then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidErr, ParameterName, StrSubstNo(TextExpectedLbl, MaximumLength)), ParameterName, StrSubstNo(TextExpectedLbl, MaximumLength));
    end;

    local procedure ApplyField(Request: JsonObject; ParameterName: Text; var Target: RecordRef; FieldNumber: Integer; var Argument: Record "Message Argument ori")
    var
        TargetField: FieldRef;
        Token: JsonToken;
        Serialized: Text;
        TextValue: Text;
        DecimalValue: Decimal;
        BooleanValue: Boolean;
        CurrentText: Text;
        CurrentBoolean: Boolean;
        CurrentDecimal: Decimal;
    begin
        if not Request.Get(ParameterName, Token) then
            exit;
        TargetField := Target.Field(FieldNumber);
        Token.WriteTo(Serialized);
        case TargetField.Type of
            FieldType::Text:
                begin
                    TextValue := ReadText(Request, ParameterName, TargetField.Length, false, Argument);
                    CurrentText := TargetField.Value;
                    if CurrentText <> TextValue then
                        TargetField.Validate(TextValue);
                end;
            FieldType::Boolean:
                begin
                    if not (Serialized in ['true', 'false']) then
                        Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidErr, ParameterName, BooleanExpectedLbl), ParameterName, BooleanExpectedLbl);
                    BooleanValue := Serialized = 'true';
                    CurrentBoolean := TargetField.Value;
                    if CurrentBoolean <> BooleanValue then
                        TargetField.Validate(BooleanValue);
                end;
            FieldType::Decimal:
                begin
                    if not Evaluate(DecimalValue, Serialized, 9) then
                        Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidErr, ParameterName, NumberExpectedLbl), ParameterName, NumberExpectedLbl);
                    CurrentDecimal := TargetField.Value;
                    if CurrentDecimal <> DecimalValue then
                        TargetField.Validate(DecimalValue);
                end;
        end;
    end;

    local procedure ApplyCategoryFields(Request: JsonObject; var Target: RecordRef; var Argument: Record "Message Argument ori")
    var
        Category: Record "Sustain. Account Category";
    begin
        ApplyField(Request, 'description', Target, Category.FieldNo("Description"), Argument);
        ApplyField(Request, 'co2', Target, Category.FieldNo("CO2"), Argument);
        ApplyField(Request, 'ch4', Target, Category.FieldNo("CH4"), Argument);
        ApplyField(Request, 'n2o', Target, Category.FieldNo("N2O"), Argument);
        ApplyField(Request, 'waterIntensity', Target, Category.FieldNo("Water Intensity"), Argument);
        ApplyField(Request, 'dischargedIntoWater', Target, Category.FieldNo("Discharged Into Water"), Argument);
        ApplyField(Request, 'wasteIntensity', Target, Category.FieldNo("Waste Intensity"), Argument);
        ApplyField(Request, 'customValue', Target, Category.FieldNo("Custom Value"), Argument);
        ApplyField(Request, 'calculateFromGeneralLedger', Target, Category.FieldNo("Calculate from General Ledger"), Argument);
        ApplyField(Request, 'glAccountFilter', Target, Category.FieldNo("G/L Account Filter"), Argument);
        ApplyField(Request, 'globalDimension1Filter', Target, Category.FieldNo("Global Dimension 1 Filter"), Argument);
        ApplyField(Request, 'globalDimension2Filter', Target, Category.FieldNo("Global Dimension 2 Filter"), Argument);
    end;

    local procedure ApplySubcategories(Request: JsonObject; CategoryCode: Code[20]; var Argument: Record "Message Argument ori")
    var
        Subcategory: Record "Sustain. Account Subcategory";
        Target: RecordRef;
        Token: JsonToken;
        EntryToken: JsonToken;
        Entries: JsonArray;
        Entry: JsonObject;
        SubcategoryCode: Code[20];
        IsNew: Boolean;
    begin
        if not Request.Get('subcategories', Token) then
            exit;
        if not Token.IsArray() then
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidErr, 'subcategories', ArrayExpectedLbl), 'subcategories', ArrayExpectedLbl);
        Entries := Token.AsArray();
        foreach EntryToken in Entries do begin
            if not EntryToken.IsObject() then
                Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidErr, 'subcategories', ObjectExpectedLbl), 'subcategories', ObjectExpectedLbl);
            Entry := EntryToken.AsObject();
            CheckKeys(Entry, true, Argument);
            SubcategoryCode := CopyStr(ReadText(Entry, 'code', 20, true, Argument), 1, 20);
            Subcategory.ReadIsolation := IsolationLevel::UpdLock;
            IsNew := not Subcategory.Get(CategoryCode, SubcategoryCode);
            if IsNew then begin
                Subcategory.Init();
                Subcategory.Validate("Category Code", CategoryCode);
                Subcategory.Validate(Code, SubcategoryCode);
            end;
            Target.GetTable(Subcategory);
            ApplyField(Entry, 'description', Target, Subcategory.FieldNo("Description"), Argument);
            ApplyField(Entry, 'emissionFactorCO2', Target, Subcategory.FieldNo("Emission Factor CO2"), Argument);
            ApplyField(Entry, 'emissionFactorCH4', Target, Subcategory.FieldNo("Emission Factor CH4"), Argument);
            ApplyField(Entry, 'emissionFactorN2O', Target, Subcategory.FieldNo("Emission Factor N2O"), Argument);
            ApplyField(Entry, 'renewableEnergy', Target, Subcategory.FieldNo("Renewable Energy"), Argument);
            Target.SetTable(Subcategory);
            if IsNew then
                Subcategory.Insert(true)
            else
                Subcategory.Modify(true);
        end;
    end;

    local procedure AddField(var Output: JsonObject; ParameterName: Text; Source: RecordRef; FieldNumber: Integer)
    var
        SourceField: FieldRef;
        TextValue: Text;
        BooleanValue: Boolean;
        DecimalValue: Decimal;
    begin
        SourceField := Source.Field(FieldNumber);
        case SourceField.Type of
            FieldType::Text:
                begin
                    TextValue := SourceField.Value;
                    Output.Add(ParameterName, TextValue);
                end;
            FieldType::Boolean:
                begin
                    BooleanValue := SourceField.Value;
                    Output.Add(ParameterName, BooleanValue);
                end;
            FieldType::Decimal:
                begin
                    DecimalValue := SourceField.Value;
                    Output.Add(ParameterName, DecimalValue);
                end;
        end;
    end;

    local procedure AddCategoryFields(var Output: JsonObject; Source: RecordRef)
    var
        Category: Record "Sustain. Account Category";
    begin
        AddField(Output, 'description', Source, Category.FieldNo("Description"));
        AddField(Output, 'co2', Source, Category.FieldNo("CO2"));
        AddField(Output, 'ch4', Source, Category.FieldNo("CH4"));
        AddField(Output, 'n2o', Source, Category.FieldNo("N2O"));
        AddField(Output, 'waterIntensity', Source, Category.FieldNo("Water Intensity"));
        AddField(Output, 'dischargedIntoWater', Source, Category.FieldNo("Discharged Into Water"));
        AddField(Output, 'wasteIntensity', Source, Category.FieldNo("Waste Intensity"));
        AddField(Output, 'customValue', Source, Category.FieldNo("Custom Value"));
        AddField(Output, 'calculateFromGeneralLedger', Source, Category.FieldNo("Calculate from General Ledger"));
        AddField(Output, 'glAccountFilter', Source, Category.FieldNo("G/L Account Filter"));
        AddField(Output, 'globalDimension1Filter', Source, Category.FieldNo("Global Dimension 1 Filter"));
        AddField(Output, 'globalDimension2Filter', Source, Category.FieldNo("Global Dimension 2 Filter"));
    end;

    local procedure ReadSubcategories(CategoryCode: Code[20]; var Entries: JsonArray)
    var
        Subcategory: Record "Sustain. Account Subcategory";
        Source: RecordRef;
        Entry: JsonObject;
    begin
        Subcategory.SetRange("Category Code", CategoryCode);
        if Subcategory.FindSet() then
            repeat
                Clear(Entry);
                Entry.Add('code', Subcategory.Code);
                Source.GetTable(Subcategory);
                AddField(Entry, 'description', Source, Subcategory.FieldNo("Description"));
                AddField(Entry, 'emissionFactorCO2', Source, Subcategory.FieldNo("Emission Factor CO2"));
                AddField(Entry, 'emissionFactorCH4', Source, Subcategory.FieldNo("Emission Factor CH4"));
                AddField(Entry, 'emissionFactorN2O', Source, Subcategory.FieldNo("Emission Factor N2O"));
                AddField(Entry, 'renewableEnergy', Source, Subcategory.FieldNo("Renewable Energy"));
                Entries.Add(Entry);
            until Subcategory.Next() = 0;
    end;

    local procedure Refuse(var Argument: Record "Message Argument ori"; ErrorCode: Enum "Bifrost Error Code ori"; MessageText: Text; ParameterName: Text; Expected: Text)
    begin
        Argument.AddError(ErrorCode, MessageText, ParameterName, '', Expected, FixLbl);
        Argument.RaiseCollectedErrors(ErrorCode, MessageText);
    end;

    /// <summary>Uses the shared configured check and Full permission capability for roster visibility.</summary>
    procedure IsEnabled(): Boolean
    var
        AccessCapability: Record "Sust Category Access ori";
        Configured: Codeunit "Sust Configured ori";
    begin
        exit(AccessCapability.WritePermission() and Configured.IsConfigured());
    end;

    /// <summary>Declares the category selection table.</summary>
    procedure GetFilterTableNo(): Integer
    begin
        exit(Database::"Sustain. Account Category");
    end;

    /// <summary>Describes the operation.</summary>
    procedure GetDescription(): Text[250]
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>Declares this operation as an inbound write.</summary>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    /// <summary>Provides bilingual search terms.</summary>
    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'sustainability, category, subcategory, emission factor, maintain category, renewable energy', Comment = 'is-IS=sjálfbærni, flokkur, undirflokkur, losunarstuðull, viðhalda flokki, endurnýjanleg orka';
    begin
        exit(KeywordsLbl);
    end;

    /// <summary>Explains selection behavior.</summary>
    procedure GetSelectionDescription(): Text
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>Summarizes this type.</summary>
    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := DescriptionLbl;
        exit(true);
    end;

    /// <summary>Explains defaults, standard side effects and transaction boundaries.</summary>
    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := NotesLbl;
        exit(true);
    end;

    /// <summary>Declares the version-one JSON envelope.</summary>
    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    begin
        Envelope.ReadFrom('{"subject":{"use":"notUsed"},"dataRequired":true,"version":"1.0","contentType":"application/json"}');
        exit(true);
    end;

    /// <summary>Identifies the target category.</summary>
    procedure GetTarget(var Target: JsonArray): Boolean
    var
        Entry: JsonObject;
    begin
        Clear(Target);
        Entry.Add('source', 'data.code');
        Entry.Add('form', 'code');
        Entry.Add('description', CodeHelpLbl);
        Target.Add(Entry);
        exit(true);
    end;

    /// <summary>Documents every accepted top-level and nested request key.</summary>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Clear(Parameters);
        Parameters.Add(Contract.Parameter('code', 'string', true, CodeHelpLbl));
        Parameters.Add(Contract.Parameter('emissionScope', 'string', false, ScopeHelpLbl));
        Parameters.Add(Contract.Parameter('calculationFoundation', 'string', false, FoundationHelpLbl));
        Parameters.Add(Contract.Parameter('subcategories', 'array', false, SubcategoriesHelpLbl));
        Parameters.Add(Contract.Parameter('description', 'string', false, StrSubstNo(TextExpectedLbl, 100)));
        Parameters.Add(Contract.Parameter('co2', 'boolean', false, FlagHelpLbl));
        Parameters.Add(Contract.Parameter('ch4', 'boolean', false, FlagHelpLbl));
        Parameters.Add(Contract.Parameter('n2o', 'boolean', false, FlagHelpLbl));
        Parameters.Add(Contract.Parameter('waterIntensity', 'boolean', false, FlagHelpLbl));
        Parameters.Add(Contract.Parameter('dischargedIntoWater', 'boolean', false, FlagHelpLbl));
        Parameters.Add(Contract.Parameter('wasteIntensity', 'boolean', false, FlagHelpLbl));
        Parameters.Add(Contract.Parameter('customValue', 'string', false, StrSubstNo(TextExpectedLbl, 100)));
        Parameters.Add(Contract.Parameter('calculateFromGeneralLedger', 'boolean', false, FlagHelpLbl));
        Parameters.Add(Contract.Parameter('glAccountFilter', 'string', false, StrSubstNo(TextExpectedLbl, 250)));
        Parameters.Add(Contract.Parameter('globalDimension1Filter', 'string', false, StrSubstNo(TextExpectedLbl, 250)));
        Parameters.Add(Contract.Parameter('globalDimension2Filter', 'string', false, StrSubstNo(TextExpectedLbl, 250)));
        exit(true);
    end;

    /// <summary>Documents the stored category and complete subcategory list.</summary>
    procedure GetResponse(var Response: JsonObject): Boolean
    var
        Fields: JsonArray;
        Entry: JsonObject;
    begin
        Clear(Response);
        Entry.Add('name', 'status');
        Entry.Add('type', 'string');
        Entry.Add('description', SuccessLbl);
        Fields.Add(Entry);
        Clear(Entry);
        Entry.Add('name', 'category');
        Entry.Add('type', 'object');
        Entry.Add('description', CategoryResponseLbl);
        Fields.Add(Entry);
        Clear(Entry);
        Entry.Add('name', 'subcategories');
        Entry.Add('type', 'array');
        Entry.Add('description', SubcategoryResponseLbl);
        Fields.Add(Entry);
        Response.Add('contentType', 'application/json');
        Response.Add('fields', Fields);
        exit(true);
    end;

    /// <summary>Documents Foundation error codes with when and fix guidance.</summary>
    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        Contract: Codeunit "Msg Contract Mgt ori";
    begin
        Clear(Errors);
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::MissingParameter, StrSubstNo(MissingErr, 'code'), CodeHelpLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::UnknownParameter, StrSubstNo(UnknownErr, '<parameter>'), FixLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidErr, '<parameter>', '<expected>'), FixLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, PermissionErr, PermissionFixLbl));
        Errors.Add(Contract.ErrorEntry("Bifrost Error Code ori"::BusinessCentralError, BusinessWhenLbl, BusinessFixLbl));
        exit(true);
    end;

    /// <summary>Describes mutation, retry safety and permission prerequisites.</summary>
    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Preconditions: JsonArray;
    begin
        Clear(Effect);
        Preconditions.Add(PreconditionsLbl);
        Effect.Add('effect', 'write');
        Effect.Add('changes', ChangesLbl);
        Effect.Add('idempotent', true);
        Effect.Add('permissionSet', 'BIFROST SustFull ori');
        Effect.Add('preconditions', Preconditions);
        exit(true);
    end;

    /// <summary>Provides a CRONUS-style example with no environment identifiers.</summary>
    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        Entry: JsonObject;
        Token: JsonToken;
    begin
        Examples.ReadFrom('[{"request":{"type":"Sustainability.Category.Set","data":{"code":"FUEL","description":"Fuel","emissionScope":"Scope 1","calculationFoundation":"Fuel/Electricity","co2":true,"subcategories":[{"code":"DIESEL","description":"Diesel","emissionFactorCO2":2.68}]}},"response":{"status":"Success","category":{"code":"FUEL","description":"Fuel","emissionScope":"Scope 1","calculationFoundation":"Fuel/Electricity","co2":true},"subcategories":[{"code":"DIESEL","description":"Diesel","emissionFactorCO2":2.68,"emissionFactorCH4":0,"emissionFactorN2O":0,"renewableEnergy":false}]}}]');
        Examples.Get(0, Token);
        Entry := Token.AsObject();
        Entry.Add('title', ExampleLbl);
        Examples.Set(0, Entry);
        exit(true);
    end;

    /// <summary>Uses Foundation metering without an additional chapter.</summary>
    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        Clear(Metering);
        exit(false);
    end;

    /// <summary>Has no additional related types chapter.</summary>
    procedure GetRelated(var Related: JsonArray): Boolean
    begin
        Clear(Related);
        exit(false);
    end;

    /// <summary>Has no additional workflow chapter.</summary>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        Clear(Workflow);
        exit(false);
    end;
}
