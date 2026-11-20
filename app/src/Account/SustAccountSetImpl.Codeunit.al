namespace Origo.Bifrost.Sustainability;

using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Journal;
using Origo.Bifrost;

/// <summary>
/// Implements the <c>Sustainability.Account.Set</c> Bifrost message type (#14). Creates or updates a
/// Sustainability Account through Validate on every supplied field, so Microsoft's own table triggers run,
/// and checks first that the subcategory belongs to the category and that an account with open journal
/// lines is not blocked. Posts nothing (decision D2).
/// </summary>
codeunit 70009210 "Sust Account Set Impl ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    Access = Internal;
    TableNo = "Message Argument ori";

    var
        DescriptionLbl: Label 'Creates or updates a sustainability account and checks that its subcategory belongs to its category.', MaxLength = 250, Comment = 'is-IS=Stofnar eða uppfærir sjálfbærnireikning og athugar að undirflokkur hans tilheyri flokki hans.';
        MissingParameterErr: Label 'The request is missing the required parameter ''%1''.', Comment = '%1 = parameter name||is-IS=Beiðnina vantar nauðsynlega færibreytu ''%1''.';
        MissingParameterExpectedTxt: Label 'The number of the sustainability account.', Comment = 'is-IS=Númer sjálfbærnireikningsins.';
        UnknownCategoryErr: Label 'The sustainability account category ''%1'' does not exist.', Comment = '%1 = category code||is-IS=Flokkur sjálfbærnireiknings ''%1'' er ekki til.';
        ExistingCategoryTxt: Label 'The code of an existing sustainability account category.', Comment = 'is-IS=Kóði fyrirliggjandi flokks sjálfbærnireiknings.';
        WrongSubcategoryErr: Label 'The subcategory ''%1'' does not belong to the sustainability account category ''%2''.', Comment = '%1 = subcategory code, %2 = category code||is-IS=Undirflokkurinn ''%1'' tilheyrir ekki flokki sjálfbærnireiknings ''%2''.';
        ExistingSubcategoryTxt: Label 'A subcategory of the account''s category.', Comment = 'is-IS=Undirflokkur í flokki reikningsins.';
        AccountInUseErr: Label 'The sustainability account ''%1'' cannot be blocked because open journal lines use it in these batches: %2.', Comment = '%1 = account number, %2 = journal template and batch names||is-IS=Ekki er hægt að loka sjálfbærnireikningnum ''%1'' því að opnar færslubókarlínur nota hann í þessum bunkum: %2.';
        NoOpenLinesTxt: Label 'No open sustainability journal lines on the account.', Comment = 'is-IS=Engar opnar færslubókarlínur sjálfbærni á reikningnum.';
        InvalidAccountTypeErr: Label 'The parameter ''accountType'' has the invalid value ''%1''.', Comment = '%1 = received value||is-IS=Færibreytan ''accountType'' hefur ógilda gildið ''%1''.';
        AccountTypeValuesTxt: Label 'Posting, Heading, Total, Begin-Total or End-Total.', Comment = 'Values are request tokens||is-IS=Posting, Heading, Total, Begin-Total eða End-Total.';
        InvalidBooleanErr: Label 'The parameter ''%1'' must be true or false.', Comment = '%1 = parameter name||is-IS=Færibreytan ''%1'' verður að vera true eða false.';
        BooleanTxt: Label 'true or false.', Comment = 'is-IS=true eða false.';
        ValueTooLongErr: Label 'The parameter ''%1'' is longer than the %2 characters allowed.', Comment = '%1 = parameter name, %2 = maximum length||is-IS=Færibreytan ''%1'' er lengri en leyfilegur hámarksfjöldi stafa, %2.';
        MaximumLengthTxt: Label '%1 characters at most.', Comment = '%1 = maximum length||is-IS=Að hámarki %1 stafir.';
        PermissionErr: Label 'You do not have permission to maintain sustainability accounts through Bifrost. Ask your administrator for the BIFROST SustFull ori permission set.', Comment = 'is-IS=Þú hefur ekki heimild til að viðhalda sjálfbærnireikningum í gegnum Bifröst. Biddu kerfisstjóra um heimildasafnið BIFROST SustFull ori.';
        PermissionExpectedTxt: Label 'The BIFROST SustFull ori permission set.', Comment = 'is-IS=Heimildasafnið BIFROST SustFull ori.';
        CorrectParameterTxt: Label 'Correct %1 and resend the request.', Comment = '%1 = parameter||is-IS=Leiðréttu %1 og sendu beiðnina aftur.';
        PostOrRemoveLinesTxt: Label 'Delete or move the open journal lines of the account, then block it.', Comment = 'is-IS=Eyddu eða færðu opnu færslubókarlínur reikningsins og lokaðu honum svo.';
        AskAdministratorTxt: Label 'Ask your administrator for the permission set, then resend the request.', Comment = 'is-IS=Biddu kerfisstjóra um heimildasafnið og sendu beiðnina svo aftur.';

    procedure IsEnabled(): Boolean
    var
        Configured: Codeunit "Sust Configured ori";
    begin
        exit(Configured.IsConfigured() and HasWriteCapability());
    end;

    procedure GetFilterTableNo() FilterTableId: Integer
    begin
        exit(Database::"Sustainability Account");
    end;

    procedure GetDescription() Description: Text[250]
    begin
        exit(DescriptionLbl);
    end;

    procedure GetKeywords(): Text
    var
        KeywordsLbl: Label 'create sustainability account, update sustainability account, emission account, carbon account, set account category, set account subcategory, block sustainability account, sustainability chart of accounts', Comment = 'is-IS=stofna sjálfbærnireikning, uppfæra sjálfbærnireikning, losunarreikningur, kolefnisreikningur, setja flokk reiknings, setja undirflokk reiknings, loka sjálfbærnireikningi, bókhaldslykill sjálfbærni';
    begin
        exit(KeywordsLbl);
    end;

    procedure GetSelectionDescription(): Text
    var
        SelectionLbl: Label 'Create or update one sustainability account: name, type, totaling, category and subcategory (checked together), direct posting, blocked and global dimensions. Writes master data and posts nothing. To read balances use Sustainability.AccountBalance.Get.', Comment = 'is-IS=Stofna eða uppfæra einn sjálfbærnireikning: heiti, tegund, samtölu, flokk og undirflokk (athugaðir saman), beina bókun, lokun og altækar víddir. Skrifar grunngögn og bókar ekkert. Til að lesa stöður skal nota Sustainability.AccountBalance.Get.';
    begin
        exit(SelectionLbl);
    end;

    procedure GetMessageDirection() MessageDirection: Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Inbound);
    end;

    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    var
        Subject: JsonObject;
        Forms: JsonArray;
    begin
        Subject.Add('use', 'optional');
        Forms.Add('string');
        Subject.Add('forms', Forms);
        Subject.Add('description', 'The number of the sustainability account. When set it is used instead of data.no, and it may be at most 20 characters long.');
        Envelope.Add('subject', Subject);
        Envelope.Add('dataRequired', true);
        Envelope.Add('version', '1.0');
        Envelope.Add('contentType', 'text/json');
        exit(true);
    end;

    procedure GetTarget(var Target: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Target.Add(ContractMgt.TargetEntry('subject', 'Sustainability Account No.', 'Used when the subject is set.'));
        Target.Add(ContractMgt.TargetEntry('data.no', 'Sustainability Account No.', 'Read when the subject is empty.'));
        exit(true);
    end;

    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Parameters.Add(ContractMgt.Parameter('no', 'string', true, 'The account number, at most 20 characters. An existing account is updated, a new number creates the account. May be supplied as the subject instead.'));
        Parameters.Add(ContractMgt.Parameter('name', 'string', false, 'The account name, at most 100 characters.'));
        Parameters.Add(ContractMgt.Parameter('accountType', 'string', false, 'Posting, Heading, Total, Begin-Total or End-Total. A new account without it is a Posting account.'));
        Parameters.Add(ContractMgt.Parameter('totaling', 'string', false, 'The account filter a Total or End-Total account sums, for example 10000..19999. Business Central refuses it on a Posting account.'));
        Parameters.Add(ContractMgt.Parameter('category', 'string', false, 'The code of an existing sustainability account category. Changing it clears the subcategory unless subcategory is also sent. Total and Begin-Total or End-Total accounts need none.'));
        Parameters.Add(ContractMgt.Parameter('subcategory', 'string', false, 'The code of a subcategory of the category (the one sent, or the account''s current one).'));
        Parameters.Add(ContractMgt.Parameter('directPosting', 'boolean', false, 'Whether journals may post directly to the account.'));
        Parameters.Add(ContractMgt.Parameter('blocked', 'boolean', false, 'Blocks or unblocks the account. Blocking is refused while open sustainability journal lines use the account.'));
        Parameters.Add(ContractMgt.Parameter('globalDimension1Code', 'string', false, 'A value of global dimension 1; empty clears it. Business Central stores it as a default dimension too.'));
        Parameters.Add(ContractMgt.Parameter('globalDimension2Code', 'string', false, 'A value of global dimension 2; empty clears it. Business Central stores it as a default dimension too.'));
        exit(true);
    end;

    procedure GetResponse(var Response: JsonObject): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Fields: JsonArray;
    begin
        Response.Add('contentType', 'text/json');
        Fields.Add(ContractMgt.ResponseField('status', 'string', 'Success when the account was stored.'));
        Fields.Add(ContractMgt.ResponseField('created', 'boolean', 'True when this call created the account, false when it updated an existing one.'));
        Fields.Add(ContractMgt.ResponseField('account', 'object', 'The account as stored: no, name, accountType, category, subcategory, emissionScope, totaling, directPosting, blocked, globalDimension1Code and globalDimension2Code.'));
        Response.Add('fields', Fields);
        exit(true);
    end;

    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::MissingParameter, 'Neither data.no nor the subject names the account (refusal MissingParameter). Nothing is written.', 'Send the account number in data.no or as the subject.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::InvalidParameter, 'Refusal InvalidCategory: the category does not exist, or the subcategory does not belong to the category. Also an accountType outside the allowed set or a value longer than its field. Nothing is written.', 'Use an existing category and one of its subcategories, or a documented value.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::InvalidParameterFormat, 'directPosting or blocked is not true or false. Nothing is written.', 'Send a JSON boolean.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PreconditionFailed, 'Refusal AccountInUse: blocked is true while open sustainability journal lines use the account; the message names their template and batch. Nothing is written.', 'Delete or move the open journal lines, then block the account.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, 'The caller does not hold BIFROST SustFull ori. Nothing is written.', 'Have BIFROST SustFull ori (or Foundation''s Full role) assigned, then call again.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::BusinessCentralError, 'A Business Central validation error, for example totaling on a Posting account, a dimension value that does not exist or a category change on an account with ledger entries. The error carries Business Central''s message; nothing is saved.', 'Correct the value named by the error and retry.'));
        Errors.Add(ContractMgt.ErrorEntry("Bifrost Error Code ori"::UnknownParameter, 'An unknown request key is warned about, or refused when the task envelope has strict true.', 'Use only declared parameter names.'));
        ContractMgt.AddRetryableWriteError(Errors);
        exit(true);
    end;

    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Preconditions: JsonArray;
    begin
        Effect.Add('effect', 'write');
        Effect.Add('changes', 'Inserts or modifies one Sustainability Account (and the Default Dimension rows Business Central keeps for its global dimensions). Changing category or subcategory also updates the open journal lines of the account, as Business Central does. Posts nothing: no sustainability ledger entry is written.');
        Effect.Add('idempotent', true);
        Effect.Add('permissionSet', 'BIFROST SustFull ori');
        Preconditions.Add('Microsoft Sustainability is installed and the caller has the permissions on its tables.');
        Preconditions.Add('A category or subcategory sent exists (Sustainability.Category.Set or the Sustainability Account Categories page).');
        Effect.Add('preconditions', Preconditions);
        exit(true);
    end;

    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        exit(false);
    end;

    procedure GetRelated(var Related: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Related.Add(ContractMgt.RelatedEntry('Data.Records.Get', 'You only read accounts and their fields.'));
        exit(true);
    end;

    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        exit(false);
    end;

    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Examples.Add(ContractMgt.Example('Create a posting account in a category',
            '{"type":"Sustainability.Account.Set","data":{"no":"11120","name":"Company cars - diesel","category":"MOBILE","subcategory":"DIESEL"}}',
            '{"status":"Success","created":true,"account":{"no":"11120","name":"Company cars - diesel","accountType":"Posting","category":"MOBILE","subcategory":"DIESEL","emissionScope":"Scope 1","totaling":"","directPosting":true,"blocked":false,"globalDimension1Code":"","globalDimension2Code":""}}'));
        Examples.Add(ContractMgt.Example('Block an account',
            '{"type":"Sustainability.Account.Set","subject":"11120","data":{"blocked":true}}',
            '{"status":"Success","created":false,"account":{"no":"11120","name":"Company cars - diesel","accountType":"Posting","category":"MOBILE","subcategory":"DIESEL","emissionScope":"Scope 1","totaling":"","directPosting":true,"blocked":true,"globalDimension1Code":"","globalDimension2Code":""}}'));
        exit(true);
    end;

    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := 'Creates the Sustainability Account when the number is new and updates it otherwise. Every field sent is set with Validate, so Business Central''s own ' +
            'rules run; a field whose value is unchanged is left alone, so the same request twice gives the same account. Fields not sent keep their values.';
        exit(true);
    end;

    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := 'The checks of category, subcategory, account type, blocked and permissions run before anything is written. The write runs in its own transaction ' +
            '(Codeunit.Run, which commits on success), so an error rolls back everything this call wrote and is answered with status Error. Under Omit Commit it runs ' +
            'inside the caller''s transaction instead. Default dimensions other than the two global dimensions are maintained with Data.Records.Set on Default Dimension.';
        exit(true);
    end;

    trigger OnRun()
    begin
        PerformWrite(Rec);
    end;

    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    begin
        Argument.AssertVersion1();
        Argument.AssertIsLicensed();
        if not HasWriteCapability() then begin
            Argument.RespondWithError("Bifrost Error Code ori"::PermissionDenied, PermissionErr, 'type', 'Sustainability.Account.Set', PermissionExpectedTxt, AskAdministratorTxt);
            exit;
        end;

        if Argument."Omit Commit" then begin
            PerformWrite(Argument);
            exit;
        end;

        if not Codeunit.Run(Codeunit::"Sust Account Set Impl ori", Argument) then
            Argument.RespondWithLastError();
    end;

    /// <summary>Checks the request and stores the account. Called directly, or through the isolated write.</summary>
    procedure PerformWrite(var Argument: Record "Message Argument ori")
    var
        SustainabilityAccount: Record "Sustainability Account";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        AccountNo: Code[20];
        Created: Boolean;
    begin
        RequestJson := Argument.GetRequestJson();
        AccountNo := GetAccountNo(RequestJson, Argument);
        CheckRequest(RequestJson, AccountNo);

        Created := not SustainabilityAccount.Get(AccountNo);
        if Created then begin
            SustainabilityAccount.Init();
            SustainabilityAccount.Validate("No.", AccountNo);
            SustainabilityAccount.Insert(true);
        end;

        ApplyFields(RequestJson, SustainabilityAccount);
        SustainabilityAccount.Modify(true);

        SustainabilityAccount.Get(AccountNo);
        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('created', Created);
        ResponseJson.Add('account', AccountToJson(SustainabilityAccount));
        Argument.SetResponseJson(ResponseJson);
        Argument."Content Type" := Argument.GetContentTypeJson();
    end;

    local procedure HasWriteCapability(): Boolean
    var
        AccessCapability: Record "Sust Account Set Access ori";
    begin
        exit(AccessCapability.WritePermission());
    end;

    local procedure GetAccountNo(RequestJson: JsonObject; var Argument: Record "Message Argument ori") AccountNo: Code[20]
    var
        TextValue: Text;
    begin
        TextValue := Argument.Subject;
        if TextValue = '' then
            TextValue := GetText(RequestJson, 'no');
        if TextValue = '' then
            RaiseRefusal("Bifrost Error Code ori"::MissingParameter, StrSubstNo(MissingParameterErr, 'no'), 'no', '', MissingParameterExpectedTxt, StrSubstNo(CorrectParameterTxt, 'no'));
        AccountNo := CheckedCode20(TextValue, 'no');
    end;

    /// <summary>Runs every refusal check before the first write, so a refusal leaves nothing changed.</summary>
    local procedure CheckRequest(RequestJson: JsonObject; AccountNo: Code[20])
    var
        SustainabilityAccount: Record "Sustainability Account";
        SustainAccountCategory: Record "Sustain. Account Category";
        SustainAccountSubcategory: Record "Sustain. Account Subcategory";
        CategoryCode: Code[20];
        SubcategoryCode: Code[20];
        AccountType: Enum "Sustainability Account Type";
    begin
        if HasKey(RequestJson, 'accountType') then
            AccountType := GetAccountType(RequestJson);
        CheckLength(RequestJson, 'name', MaxStrLen(SustainabilityAccount.Name));
        CheckLength(RequestJson, 'totaling', MaxStrLen(SustainabilityAccount.Totaling));
        CheckLength(RequestJson, 'globalDimension1Code', MaxStrLen(SustainabilityAccount."Global Dimension 1 Code"));
        CheckLength(RequestJson, 'globalDimension2Code', MaxStrLen(SustainabilityAccount."Global Dimension 2 Code"));
        if HasKey(RequestJson, 'directPosting') then
            GetBoolean(RequestJson, 'directPosting');

        if SustainabilityAccount.Get(AccountNo) then
            CategoryCode := SustainabilityAccount.Category;
        if HasKey(RequestJson, 'category') then begin
            CategoryCode := CheckedCode20(GetText(RequestJson, 'category'), 'category');
            if CategoryCode <> '' then
                if not SustainAccountCategory.Get(CategoryCode) then
                    RaiseRefusal("Bifrost Error Code ori"::InvalidParameter, StrSubstNo(UnknownCategoryErr, CategoryCode), 'category', CategoryCode, ExistingCategoryTxt, StrSubstNo(CorrectParameterTxt, 'category'));
        end;
        if HasKey(RequestJson, 'subcategory') then begin
            SubcategoryCode := CheckedCode20(GetText(RequestJson, 'subcategory'), 'subcategory');
            if SubcategoryCode <> '' then
                if not SustainAccountSubcategory.Get(CategoryCode, SubcategoryCode) then
                    RaiseRefusal("Bifrost Error Code ori"::InvalidParameter, StrSubstNo(WrongSubcategoryErr, SubcategoryCode, CategoryCode), 'subcategory', SubcategoryCode, ExistingSubcategoryTxt, StrSubstNo(CorrectParameterTxt, 'subcategory'));
        end;

        if HasKey(RequestJson, 'blocked') then
            if GetBoolean(RequestJson, 'blocked') then
                CheckNoOpenJournalLines(AccountNo);
    end;

    local procedure CheckNoOpenJournalLines(AccountNo: Code[20])
    var
        SustainabilityJnlLine: Record "Sustainability Jnl. Line";
        Batches: List of [Text];
        BatchName: Text;
        BatchNames: TextBuilder;
    begin
        SustainabilityJnlLine.SetRange("Account No.", AccountNo);
        SustainabilityJnlLine.SetLoadFields("Journal Template Name", "Journal Batch Name");
        if not SustainabilityJnlLine.FindSet() then
            exit;
        repeat
            BatchName := SustainabilityJnlLine."Journal Template Name" + '/' + SustainabilityJnlLine."Journal Batch Name";
            if not Batches.Contains(BatchName) then
                Batches.Add(BatchName);
        until SustainabilityJnlLine.Next() = 0;
        foreach BatchName in Batches do begin
            if BatchNames.Length() > 0 then
                BatchNames.Append(', ');
            BatchNames.Append(BatchName);
        end;
        RaiseRefusal("Bifrost Error Code ori"::PreconditionFailed, StrSubstNo(AccountInUseErr, AccountNo, BatchNames.ToText()), 'blocked', 'true', NoOpenLinesTxt, PostOrRemoveLinesTxt);
    end;

    /// <summary>Sets every field the request carries with Validate, in Business Central's dependency order; unchanged values are left alone.</summary>
    local procedure ApplyFields(RequestJson: JsonObject; var SustainabilityAccount: Record "Sustainability Account")
    var
        TextValue: Text;
        CodeValue: Code[20];
        BooleanValue: Boolean;
        AccountType: Enum "Sustainability Account Type";
    begin
        if HasKey(RequestJson, 'accountType') then begin
            AccountType := GetAccountType(RequestJson);
            if SustainabilityAccount."Account Type" <> AccountType then
                SustainabilityAccount.Validate("Account Type", AccountType);
        end;
        if HasKey(RequestJson, 'name') then begin
            TextValue := GetText(RequestJson, 'name');
            if SustainabilityAccount.Name <> TextValue then
                SustainabilityAccount.Validate(Name, CopyStr(TextValue, 1, MaxStrLen(SustainabilityAccount.Name)));
        end;
        if HasKey(RequestJson, 'totaling') then begin
            TextValue := GetText(RequestJson, 'totaling');
            if SustainabilityAccount.Totaling <> TextValue then
                SustainabilityAccount.Validate(Totaling, CopyStr(TextValue, 1, MaxStrLen(SustainabilityAccount.Totaling)));
        end;
        if HasKey(RequestJson, 'category') then begin
            CodeValue := CheckedCode20(GetText(RequestJson, 'category'), 'category');
            if SustainabilityAccount.Category <> CodeValue then
                SustainabilityAccount.Validate(Category, CodeValue);
        end;
        if HasKey(RequestJson, 'subcategory') then begin
            CodeValue := CheckedCode20(GetText(RequestJson, 'subcategory'), 'subcategory');
            if SustainabilityAccount.Subcategory <> CodeValue then
                SustainabilityAccount.Validate(Subcategory, CodeValue);
        end;
        if HasKey(RequestJson, 'directPosting') then begin
            BooleanValue := GetBoolean(RequestJson, 'directPosting');
            if SustainabilityAccount."Direct Posting" <> BooleanValue then
                SustainabilityAccount.Validate("Direct Posting", BooleanValue);
        end;
        if HasKey(RequestJson, 'blocked') then begin
            BooleanValue := GetBoolean(RequestJson, 'blocked');
            if SustainabilityAccount.Blocked <> BooleanValue then
                SustainabilityAccount.Validate(Blocked, BooleanValue);
        end;
        if HasKey(RequestJson, 'globalDimension1Code') then begin
            CodeValue := CheckedCode20(GetText(RequestJson, 'globalDimension1Code'), 'globalDimension1Code');
            if SustainabilityAccount."Global Dimension 1 Code" <> CodeValue then
                SustainabilityAccount.Validate("Global Dimension 1 Code", CodeValue);
        end;
        if HasKey(RequestJson, 'globalDimension2Code') then begin
            CodeValue := CheckedCode20(GetText(RequestJson, 'globalDimension2Code'), 'globalDimension2Code');
            if SustainabilityAccount."Global Dimension 2 Code" <> CodeValue then
                SustainabilityAccount.Validate("Global Dimension 2 Code", CodeValue);
        end;
    end;

    /// <summary>The account in the shape of the account rows of Sustainability.AccountBalance.Get, without amounts.</summary>
    procedure AccountToJson(var SustainabilityAccount: Record "Sustainability Account") Account: JsonObject
    begin
        SustainabilityAccount.CalcFields("Emission Scope");
        Account.Add('no', SustainabilityAccount."No.");
        Account.Add('name', SustainabilityAccount.Name);
        Account.Add('accountType', EnumName(SustainabilityAccount."Account Type"));
        Account.Add('category', SustainabilityAccount.Category);
        Account.Add('subcategory', SustainabilityAccount.Subcategory);
        Account.Add('emissionScope', SustainabilityAccount."Emission Scope".Names().Get(SustainabilityAccount."Emission Scope".Ordinals().IndexOf(SustainabilityAccount."Emission Scope".AsInteger())));
        Account.Add('totaling', SustainabilityAccount.Totaling);
        Account.Add('directPosting', SustainabilityAccount."Direct Posting");
        Account.Add('blocked', SustainabilityAccount.Blocked);
        Account.Add('globalDimension1Code', SustainabilityAccount."Global Dimension 1 Code");
        Account.Add('globalDimension2Code', SustainabilityAccount."Global Dimension 2 Code");
    end;

    local procedure EnumName(AccountType: Enum "Sustainability Account Type"): Text
    begin
        exit(AccountType.Names().Get(AccountType.Ordinals().IndexOf(AccountType.AsInteger())));
    end;

    local procedure GetAccountType(RequestJson: JsonObject) AccountType: Enum "Sustainability Account Type"
    var
        TextValue: Text;
        Index: Integer;
        Name: Text;
    begin
        TextValue := GetText(RequestJson, 'accountType');
        foreach Name in AccountType.Names() do begin
            Index += 1;
            if UpperCase(Name) = UpperCase(TextValue) then
                exit(Enum::"Sustainability Account Type".FromInteger(AccountType.Ordinals().Get(Index)));
        end;
        RaiseRefusal("Bifrost Error Code ori"::InvalidParameter, StrSubstNo(InvalidAccountTypeErr, TextValue), 'accountType', TextValue, AccountTypeValuesTxt, StrSubstNo(CorrectParameterTxt, 'accountType'));
    end;

    local procedure HasKey(RequestJson: JsonObject; PropertyName: Text): Boolean
    begin
        exit(RequestJson.Contains(PropertyName));
    end;

    local procedure GetText(RequestJson: JsonObject; PropertyName: Text): Text
    var
        JToken: JsonToken;
    begin
        if not RequestJson.Get(PropertyName, JToken) then
            exit('');
        if not JToken.IsValue() then
            exit('');
        if JToken.AsValue().IsNull() then
            exit('');
        exit(JToken.AsValue().AsText());
    end;

    local procedure GetBoolean(RequestJson: JsonObject; PropertyName: Text): Boolean
    begin
        case LowerCase(GetText(RequestJson, PropertyName)) of
            'true':
                exit(true);
            'false':
                exit(false);
        end;
        RaiseRefusal("Bifrost Error Code ori"::InvalidParameterFormat, StrSubstNo(InvalidBooleanErr, PropertyName), PropertyName, GetText(RequestJson, PropertyName), BooleanTxt, StrSubstNo(CorrectParameterTxt, PropertyName));
    end;

    local procedure CheckLength(RequestJson: JsonObject; PropertyName: Text; MaximumLength: Integer)
    var
        TextValue: Text;
    begin
        if not HasKey(RequestJson, PropertyName) then
            exit;
        TextValue := GetText(RequestJson, PropertyName);
        if StrLen(TextValue) > MaximumLength then
            RaiseRefusal("Bifrost Error Code ori"::InvalidParameter, StrSubstNo(ValueTooLongErr, PropertyName, MaximumLength), PropertyName, TextValue, StrSubstNo(MaximumLengthTxt, MaximumLength), StrSubstNo(CorrectParameterTxt, PropertyName));
    end;

    local procedure CheckedCode20(TextValue: Text; PropertyName: Text) Value: Code[20]
    begin
        if StrLen(TextValue) > MaxStrLen(Value) then
            RaiseRefusal("Bifrost Error Code ori"::InvalidParameter, StrSubstNo(ValueTooLongErr, PropertyName, MaxStrLen(Value)), PropertyName, TextValue, StrSubstNo(MaximumLengthTxt, MaxStrLen(Value)), StrSubstNo(CorrectParameterTxt, PropertyName));
        Value := CopyStr(TextValue, 1, MaxStrLen(Value));
    end;

    /// <summary>Raises a structured refusal; the isolated write rolls back and Foundation answers it with status Error.</summary>
    local procedure RaiseRefusal(ErrorCode: Enum "Bifrost Error Code ori"; MessageText: Text; ParameterName: Text; Received: Text; Expected: Text; NextStep: Text)
    var
        TempArgument: Record "Message Argument ori" temporary;
    begin
        if Received = '' then
            Received := '<missing>';
        TempArgument.AddError(ErrorCode, MessageText, ParameterName, Received, Expected, NextStep);
        TempArgument.RaiseCollectedErrors("Bifrost Error Code ori"::MultipleErrors, MessageText);
    end;
}
