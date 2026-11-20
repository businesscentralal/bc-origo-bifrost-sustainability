namespace Origo.Bifrost.Sustainability;

using Microsoft.Sustainability.Account;
using Microsoft.Sustainability.Ledger;
using Origo.Bifrost;

/// <summary>Reads native account FlowFields and stored CO2e without changing sustainability data.</summary>
codeunit 70009208 "Sust Account Bal Impl ori" implements "Msg Interface ori", "Msg Discovery ori", "Msg Contract ori"
{
    TableNo = "Message Argument ori";
    Access = Internal;

    var
        DescriptionLbl: Label 'Returns sustainability account net change and balances, including totals, for selected dates and dimensions.', Comment = 'is-IS=Skilar hreyfingu og stöðu sjálfbærnireikninga, ásamt samtölum, fyrir valdar dagsetningar og víddir.';
        KeywordsLbl: Label 'sustainability account balance, emission net change, sustainability totals', Comment = 'is-IS=staða sjálfbærnireiknings, hreyfing losunar, samtölur sjálfbærni';
        NotesLbl: Label 'Read-only and idempotent. Native FlowFields calculate six measures; CO2e sums the stored ledger amount with identical filters. Totaling applies to Total and End Total accounts. Balance uses asOfDate, otherwise toDate, otherwise all dates. Heading and Begin Total rows have zero values. No Commit is called. Foundation may record message processing. Hidden catalogue entries remain callable by name.', Comment = 'is-IS=Aðeins lestur og endurtekin köll breyta engu. Innbyggðir flæðireitir reikna sex mælikvarða; CO2e leggur saman geymda fjárhæð færslna með sömu síum. Samtölusía gildir fyrir samtölu- og lokasamtölureikninga. Staða miðast við asOfDate, annars toDate, annars allar dagsetningar. Fyrirsagnar- og upphafssamtölulínur hafa núllgildi. Ekki er kallað á Commit. Grunnforritið getur skráð skilaboðavinnslu. Faldar tegundir má áfram kalla eftir nafni.';
        ChangesLbl: Label 'No sustainability data changes and no posting. Reads account metadata and ledger totals.', Comment = 'is-IS=Engum sjálfbærnigögnum er breytt og ekkert bókað. Les lýsigögn reikninga og samtölur færslna.';
        PermissionLbl: Label 'Read permission on sustainability accounts and ledger entries is required.', Comment = 'is-IS=Lesréttindi á sjálfbærnireikningum og sjálfbærnifærslum eru nauðsynleg.';
        FixPermissionLbl: Label 'Assign BIFROST Read ori, including BIFROST SustRead ori.', Comment = 'is-IS=Úthlutaðu BIFROST Read ori, ásamt BIFROST SustRead ori.';
        AccountNotFoundErr: Label 'Sustainability account ''%1'' does not exist.', Comment = '%1 = received value; %2 = parameter name||is-IS=Sjálfbærnireikningur ''%1'' er ekki til.';
        FixAccountLbl: Label 'Use an existing sustainability account number.', Comment = 'is-IS=Notaðu númer sjálfbærnireiknings sem er til.';
        InvalidFilterErr: Label 'Invalid filter ''%1'' for %2.', Comment = '%1 = received value; %2 = parameter name||is-IS=Ógild sía ''%1'' fyrir %2.';
        FixFilterLbl: Label 'Correct the Business Central filter expression.', Comment = 'is-IS=Leiðréttu síusetninguna í Business Central.';
        InvalidPeriodErr: Label 'Dates must be ISO dates (YYYY-MM-DD), and fromDate must not be after toDate.', Comment = 'is-IS=Dagsetningar verða að vera á ISO-sniði (YYYY-MM-DD) og fromDate má ekki vera á eftir toDate.';
        FixPeriodLbl: Label 'Send valid ISO dates and an ordered date range.', Comment = 'is-IS=Sendu gildar ISO-dagsetningar og rétt raðað tímabil.';
        InvalidParameterErr: Label 'Invalid or unknown parameter ''%1''.', Comment = '%1 = received value; %2 = parameter name||is-IS=Ógild eða óþekkt færibreyta ''%1''.';
        FixParameterLbl: Label 'Use only the documented keys and JSON types; accountNo and accountFilter are mutually exclusive.', Comment = 'is-IS=Notaðu aðeins skráða lykla og JSON-gagnagerðir; accountNo og accountFilter má ekki nota saman.';
        AccountNoLbl: Label 'Exact account number, maximum 20 characters. Cannot be combined with accountFilter.', Comment = 'is-IS=Nákvæmt reikningsnúmer, að hámarki 20 stafir. Má ekki nota með accountFilter.';
        AccountFilterLbl: Label 'Business Central account-number filter. Omission selects all accounts.', Comment = 'is-IS=Business Central sía fyrir reikningsnúmer. Ef henni er sleppt eru allir reikningar valdir.';
        FromDateLbl: Label 'Inclusive net-change start date in YYYY-MM-DD format. Omission means no lower bound.', Comment = 'is-IS=Upphafsdagur hreyfingar, meðtalinn, á sniðinu YYYY-MM-DD. Ef honum er sleppt eru engin neðri mörk.';
        ToDateLbl: Label 'Inclusive net-change end date in YYYY-MM-DD format. Also the default balance date.', Comment = 'is-IS=Lokadagur hreyfingar, meðtalinn, á sniðinu YYYY-MM-DD. Einnig sjálfgefinn stöðudagur.';
        AsOfDateLbl: Label 'Inclusive balance date in YYYY-MM-DD format, independent of fromDate; defaults to toDate, otherwise all dates.', Comment = 'is-IS=Stöðudagur, meðtalinn, á sniðinu YYYY-MM-DD, óháður fromDate; sjálfgefið toDate, annars allar dagsetningar.';
        Dimension1Lbl: Label 'Business Central Global Dimension 1 filter on ledger entries.', Comment = 'is-IS=Business Central sía fyrir altæka vídd 1 á færslum.';
        Dimension2Lbl: Label 'Business Central Global Dimension 2 filter on ledger entries.', Comment = 'is-IS=Business Central sía fyrir altæka vídd 2 á færslum.';
        ResponsibilityLbl: Label 'Business Central responsibility-center filter on ledger entries.', Comment = 'is-IS=Business Central sía fyrir ábyrgðarstöð á færslum.';
        IncludeZeroLbl: Label 'Include accounts whose net change and balance are both zero for all measures; defaults to false.', Comment = 'is-IS=Taka með reikninga með núllhreyfingu og núllstöðu í öllum mælikvörðum; sjálfgefið false.';
        ResponseLbl: Label 'Account rows with no, name, invariant accountType, indentation and netChange/balance objects containing co2, ch4, n2o, co2e, water, dischargedWater and waste. All amounts retain their stored unit.', Comment = 'is-IS=Reikningslínur með no, name, tungumálaóháðu accountType, indentation og netChange/balance-hlutum með co2, ch4, n2o, co2e, water, dischargedWater og waste. Allar fjárhæðir halda geymdri einingu.';
        StatusLbl: Label 'Success when the selected account balances were read.', Comment = 'is-IS=Success þegar stöður valinna reikninga voru lesnar.';
        ExampleLbl: Label 'Read one CRONUS-style account including zero balances', Comment = 'is-IS=Lesa einn reikning að hætti CRONUS ásamt núllstöðum';
        NativeErrorLbl: Label 'Business Central could not read the selected accounts or ledger amounts.', Comment = 'is-IS=Business Central gat ekki lesið valda reikninga eða fjárhæðir færslna.';
        FixNativeLbl: Label 'Review the native error and correct the account setup or filters.', Comment = 'is-IS=Farðu yfir innbyggðu villuna og leiðréttu reikningsuppsetningu eða síur.';

    trigger OnRun()
    begin
        ExecuteBifrostTask(Rec);
    end;

    /// <summary>Uses the shared visibility rule and native read permissions.</summary>
    procedure IsEnabled(): Boolean
    var
        Account: Record "Sustainability Account";
        LedgerEntry: Record "Sustainability Ledger Entry";
        Configured: Codeunit "Sust Configured ori";
    begin
        exit(Account.ReadPermission() and LedgerEntry.ReadPermission() and Configured.IsConfigured());
    end;

    /// <summary>Identifies the native account table.</summary>
    procedure GetFilterTableNo(): Integer
    begin
        exit(Database::"Sustainability Account");
    end;

    /// <summary>Provides the translated catalogue description.</summary>
    procedure GetDescription(): Text[250]
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>Provides bilingual search phrases.</summary>
    procedure GetKeywords(): Text
    begin
        exit(KeywordsLbl);
    end;

    /// <summary>Explains the account calculation.</summary>
    procedure GetSelectionDescription(): Text
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>Reads business data without posting.</summary>
    procedure GetMessageDirection(): Enum "Msg Direction ori"
    begin
        exit(Enum::"Msg Direction ori"::Outbound);
    end;

    /// <summary>Validates input and returns a complete read result or a structured refusal.</summary>
    procedure ExecuteBifrostTask(var Argument: Record "Message Argument ori")
    var
        Account: Record "Sustainability Account";
        LedgerEntry: Record "Sustainability Ledger Entry";
        RequestJson: JsonObject;
        Response: JsonObject;
        Token: JsonToken;
        ParameterName: Text;
        Value: Text;
        AccountNo: Text;
        AccountFilter: Text;
        FromDate: Date;
        ToDate: Date;
        AsOfDate: Date;
        IncludeZero: Boolean;
    begin
        Argument.AssertVersion1();
        Argument.AssertIsLicensed();
        if not (Account.ReadPermission() and LedgerEntry.ReadPermission()) then begin
            Refuse(Argument, "Bifrost Error Code ori"::PermissionDenied, 'PermissionDenied', PermissionLbl, '', '', FixPermissionLbl);
            exit;
        end;
        RequestJson := Argument.GetRequestJson();
        foreach ParameterName in RequestJson.Keys() do
            if not (ParameterName in ['accountNo', 'accountFilter', 'fromDate', 'toDate', 'asOfDate', 'globalDimension1Filter', 'globalDimension2Filter', 'responsibilityCenterFilter', 'includeZero']) then begin
                InvalidParameter(Argument, ParameterName);
                exit;
            end;
        if not ReadText(RequestJson, 'accountNo', AccountNo, Argument) then
            exit;
        if not ReadText(RequestJson, 'accountFilter', AccountFilter, Argument) then
            exit;
        if (StrLen(AccountNo) > MaxStrLen(Account."No.")) or ((AccountNo <> '') and (AccountFilter <> '')) then begin
            InvalidParameter(Argument, 'accountNo');
            exit;
        end;
        if AccountNo <> '' then begin
            if not Account.Get(AccountNo) then begin
                Refuse(Argument, "Bifrost Error Code ori"::RecordNotFound, 'AccountNotFound', StrSubstNo(AccountNotFoundErr, AccountNo), 'accountNo', AccountNo, FixAccountLbl);
                exit;
            end;
            Account.SetRange("No.", AccountNo);
        end else
            if not ApplyFilter(Account, Account.FieldNo("No."), AccountFilter, 'accountFilter', Argument) then
                exit;
        if not ReadDate(RequestJson, 'fromDate', FromDate, Argument) then
            exit;
        if not ReadDate(RequestJson, 'toDate', ToDate, Argument) then
            exit;
        if not ReadDate(RequestJson, 'asOfDate', AsOfDate, Argument) then
            exit;
        if (FromDate <> 0D) and (ToDate <> 0D) and (FromDate > ToDate) then begin
            Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, 'InvalidPeriod', InvalidPeriodErr, 'fromDate', Format(FromDate, 0, 9), FixPeriodLbl);
            exit;
        end;
        if AsOfDate = 0D then
            AsOfDate := ToDate;
        if not ReadText(RequestJson, 'globalDimension1Filter', Value, Argument) then
            exit;
        if not ApplyFilter(Account, Account.FieldNo("Global Dimension 1 Filter"), Value, 'globalDimension1Filter', Argument) then
            exit;
        if not ReadText(RequestJson, 'globalDimension2Filter', Value, Argument) then
            exit;
        if not ApplyFilter(Account, Account.FieldNo("Global Dimension 2 Filter"), Value, 'globalDimension2Filter', Argument) then
            exit;
        if not ReadText(RequestJson, 'responsibilityCenterFilter', Value, Argument) then
            exit;
        if not ApplyFilter(Account, Account.FieldNo("Responsibility Center Filter"), Value, 'responsibilityCenterFilter', Argument) then
            exit;
        if RequestJson.Get('includeZero', Token) then begin
            Token.WriteTo(Value);
            if not (Value in ['true', 'false']) then begin
                InvalidParameter(Argument, 'includeZero');
                exit;
            end;
            IncludeZero := Value = 'true';
        end;
        if not TryReadAccounts(Account, FromDate, ToDate, AsOfDate, IncludeZero, Response) then begin
            Argument.RespondWithLastError();
            exit;
        end;
        Argument.SetResponseJson(Response);
        Argument."Content Type" := 'text/json';
    end;

    local procedure ReadText(RequestJson: JsonObject; ParameterName: Text; var Value: Text; var Argument: Record "Message Argument ori"): Boolean
    var
        Token: JsonToken;
        Serialized: Text;
    begin
        Clear(Value);
        if not RequestJson.Get(ParameterName, Token) then
            exit(true);
        Token.WriteTo(Serialized);
        if not Serialized.StartsWith('"') then begin
            InvalidParameter(Argument, ParameterName);
            exit(false);
        end;
        Value := Token.AsValue().AsText();
        exit(true);
    end;

    local procedure ReadDate(RequestJson: JsonObject; ParameterName: Text; var Value: Date; var Argument: Record "Message Argument ori"): Boolean
    var
        Token: JsonToken;
        DateText: Text;
    begin
        if not RequestJson.Get(ParameterName, Token) then
            exit(true);
        if TryDate(Token, Value, DateText) then
            exit(true);
        Refuse(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, 'InvalidPeriod', InvalidPeriodErr, ParameterName, DateText, FixPeriodLbl);
        exit(false);
    end;

    [TryFunction]
    local procedure TryDate(Token: JsonToken; var Value: Date; var DateText: Text)
    var
        Serialized: Text;
    begin
        Token.WriteTo(Serialized);
        if not Serialized.StartsWith('"') then
            Error(InvalidPeriodErr);
        DateText := Token.AsValue().AsText();
        if StrLen(DateText) <> 10 then
            Error(InvalidPeriodErr);
        Evaluate(Value, DateText, 9);
        if (Value = 0D) or (Format(Value, 0, 9) <> DateText) then
            Error(InvalidPeriodErr);
    end;

    local procedure ApplyFilter(var Account: Record "Sustainability Account"; FieldNo: Integer; Value: Text; ParameterName: Text; var Argument: Record "Message Argument ori"): Boolean
    begin
        if TryFilter(Account, FieldNo, Value) then
            exit(true);
        Refuse(Argument, "Bifrost Error Code ori"::InvalidParameterFormat, 'InvalidFilter', StrSubstNo(InvalidFilterErr, Value, ParameterName), ParameterName, Value, FixFilterLbl);
        exit(false);
    end;

    [TryFunction]
    local procedure TryFilter(var Account: Record "Sustainability Account"; FieldNo: Integer; Value: Text)
    var
        AccountRef: RecordRef;
        FilterField: FieldRef;
    begin
        AccountRef.GetTable(Account);
        FilterField := AccountRef.Field(FieldNo);
        FilterField.SetFilter(Value);
        AccountRef.SetTable(Account);
    end;

    local procedure InvalidParameter(var Argument: Record "Message Argument ori"; ParameterName: Text)
    begin
        Refuse(Argument, "Bifrost Error Code ori"::InvalidParameter, 'InvalidParameter', StrSubstNo(InvalidParameterErr, ParameterName), ParameterName, '', FixParameterLbl);
    end;

    local procedure Refuse(var Argument: Record "Message Argument ori"; ErrorCode: Enum "Bifrost Error Code ori"; Refusal: Text; MessageText: Text; Parameter: Text; Received: Text; Fix: Text)
    var
        Response: JsonObject;
    begin
        Argument.RespondWithError(ErrorCode, MessageText, Parameter, Received, '', Fix);
        Response := Argument.GetResponseJson();
        Response.Add('refusal', Refusal);
        Argument.SetResponseJson(Response);
    end;

    [TryFunction]
    local procedure TryReadAccounts(var Account: Record "Sustainability Account"; FromDate: Date; ToDate: Date; AsOfDate: Date; IncludeZero: Boolean; var Response: JsonObject)
    var
        BalanceAccount: Record "Sustainability Account";
        Row: JsonObject;
        NetChange: JsonObject;
        Balance: JsonObject;
        Accounts: JsonArray;
        Nonzero: Boolean;
    begin
        Account.ReadIsolation := IsolationLevel::ReadCommitted;
        Account.SetLoadFields("No.", Name, "Account Type", Indentation, Totaling);
        BalanceAccount.CopyFilters(Account);
        BalanceAccount.ReadIsolation := IsolationLevel::ReadCommitted;
        SetPeriod(Account, FromDate, ToDate);
        SetPeriod(BalanceAccount, 0D, AsOfDate);
        Account.SetAutoCalcFields("Net Change (CO2)", "Net Change (CH4)", "Net Change (N2O)", "Net Change (Water)", "Net Change (Disch. Water)", "Net Change (Waste)");
        BalanceAccount.SetAutoCalcFields("Net Change (CO2)", "Net Change (CH4)", "Net Change (N2O)", "Net Change (Water)", "Net Change (Disch. Water)", "Net Change (Waste)");
        if Account.FindSet() then
            repeat
                Clear(Row);
                Clear(NetChange);
                Clear(Balance);
                BalanceAccount.Get(Account."No.");
                Nonzero := AddAmounts(Account, NetChange);
                Nonzero := AddAmounts(BalanceAccount, Balance) or Nonzero;
                if IncludeZero or Nonzero then begin
                    Row.Add('no', Account."No.");
                    Row.Add('name', Account.Name);
                    Row.Add('accountType', Account."Account Type".Names().Get(Account."Account Type".Ordinals().IndexOf(Account."Account Type".AsInteger())));
                    Row.Add('indentation', Account.Indentation);
                    Row.Add('netChange', NetChange);
                    Row.Add('balance', Balance);
                    Accounts.Add(Row);
                end;
            until Account.Next() = 0;
        Clear(Response);
        Response.Add('status', 'Success');
        Response.Add('accounts', Accounts);
    end;

    local procedure SetPeriod(var Account: Record "Sustainability Account"; FromDate: Date; ToDate: Date)
    begin
        if ToDate <> 0D then
            Account.SetRange("Date Filter", FromDate, ToDate)
        else
            if FromDate <> 0D then
                Account.SetFilter("Date Filter", '>=%1', FromDate);
    end;

    local procedure AddAmounts(var Account: Record "Sustainability Account"; var Amounts: JsonObject) Nonzero: Boolean
    var
        CO2e: Decimal;
    begin
        CO2e := ReadCO2e(Account);
        Amounts.Add('co2', Account."Net Change (CO2)");
        Amounts.Add('ch4', Account."Net Change (CH4)");
        Amounts.Add('n2o', Account."Net Change (N2O)");
        Amounts.Add('water', Account."Net Change (Water)");
        Amounts.Add('dischargedWater', Account."Net Change (Disch. Water)");
        Amounts.Add('waste', Account."Net Change (Waste)");
        Amounts.Add('co2e', CO2e);
        Nonzero := (CO2e <> 0) or
            (Account."Net Change (CO2)" <> 0) or
            (Account."Net Change (CH4)" <> 0) or
            (Account."Net Change (N2O)" <> 0) or
            (Account."Net Change (Water)" <> 0) or
            (Account."Net Change (Disch. Water)" <> 0) or
            (Account."Net Change (Waste)" <> 0);
    end;

    local procedure ReadCO2e(var Account: Record "Sustainability Account"): Decimal
    var
        LedgerEntry: Record "Sustainability Ledger Entry";
    begin
        if Account."Account Type" in [Account."Account Type"::Heading, Account."Account Type"::"Begin-Total"] then
            exit(0);
        LedgerEntry.ReadIsolation := IsolationLevel::ReadCommitted;
        if Account.Totaling <> '' then
            LedgerEntry.SetFilter("Account No.", Account.Totaling)
        else
            LedgerEntry.SetRange("Account No.", Account."No.");
        LedgerEntry.SetFilter("Posting Date", Account.GetFilter("Date Filter"));
        LedgerEntry.SetFilter("Global Dimension 1 Code", Account.GetFilter("Global Dimension 1 Filter"));
        LedgerEntry.SetFilter("Global Dimension 2 Code", Account.GetFilter("Global Dimension 2 Filter"));
        LedgerEntry.SetFilter("Responsibility Center", Account.GetFilter("Responsibility Center Filter"));
        LedgerEntry.CalcSums("CO2e Emission");
        exit(LedgerEntry."CO2e Emission");
    end;

    /// <summary>Describes the optional JSON request.</summary>
    procedure GetEnvelope(var Envelope: JsonObject): Boolean
    begin
        Clear(Envelope);
        Envelope.ReadFrom('{"subject":{"use":"none"},"dataRequired":false,"version":"1.0","contentType":"text/json"}');
        exit(true);
    end;

    /// <summary>Account selection is described by the parameters.</summary>
    procedure GetTarget(var Target: JsonArray): Boolean
    begin
        Clear(Target);
        exit(false);
    end;

    /// <summary>Documents each accepted request key.</summary>
    procedure GetParameters(var Parameters: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Clear(Parameters);
        Parameters.Add(ContractMgt.Parameter('accountNo', 'string', false, AccountNoLbl));
        Parameters.Add(ContractMgt.Parameter('accountFilter', 'string', false, AccountFilterLbl));
        Parameters.Add(ContractMgt.Parameter('fromDate', 'string', false, FromDateLbl));
        Parameters.Add(ContractMgt.Parameter('toDate', 'string', false, ToDateLbl));
        Parameters.Add(ContractMgt.Parameter('asOfDate', 'string', false, AsOfDateLbl));
        Parameters.Add(ContractMgt.Parameter('globalDimension1Filter', 'string', false, Dimension1Lbl));
        Parameters.Add(ContractMgt.Parameter('globalDimension2Filter', 'string', false, Dimension2Lbl));
        Parameters.Add(ContractMgt.Parameter('responsibilityCenterFilter', 'string', false, ResponsibilityLbl));
        Parameters.Add(ContractMgt.Parameter('includeZero', 'boolean', false, IncludeZeroLbl));
        exit(true);
    end;

    /// <summary>Describes the account rows and measures.</summary>
    procedure GetResponse(var Response: JsonObject): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Fields: JsonArray;
    begin
        Clear(Response);
        Fields.Add(ContractMgt.ResponseField('status', 'string', StatusLbl));
        Fields.Add(ContractMgt.ResponseField('accounts', 'array', ResponseLbl));
        Response.Add('contentType', 'text/json');
        Response.Add('fields', Fields);
        exit(true);
    end;

    /// <summary>Documents Foundation error codes and their named refusals.</summary>
    procedure GetErrors(var Errors: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
        Entry: JsonObject;
    begin
        Clear(Errors);
        Entry := ContractMgt.ErrorEntry("Bifrost Error Code ori"::RecordNotFound, AccountNotFoundErr, FixAccountLbl);
        Entry.Add('refusal', 'AccountNotFound');
        Errors.Add(Entry);
        Entry := ContractMgt.ErrorEntry("Bifrost Error Code ori"::InvalidParameterFormat, InvalidFilterErr, FixFilterLbl);
        Entry.Add('refusal', 'InvalidFilter');
        Errors.Add(Entry);
        Entry := ContractMgt.ErrorEntry("Bifrost Error Code ori"::InvalidParameterFormat, InvalidPeriodErr, FixPeriodLbl);
        Entry.Add('refusal', 'InvalidPeriod');
        Errors.Add(Entry);
        Entry := ContractMgt.ErrorEntry("Bifrost Error Code ori"::InvalidParameter, InvalidPeriodErr, FixPeriodLbl);
        Entry.Add('refusal', 'InvalidPeriod');
        Errors.Add(Entry);
        Entry := ContractMgt.ErrorEntry("Bifrost Error Code ori"::PermissionDenied, PermissionLbl, FixPermissionLbl);
        Entry.Add('refusal', 'PermissionDenied');
        Errors.Add(Entry);
        Entry := ContractMgt.ErrorEntry("Bifrost Error Code ori"::InvalidParameter, InvalidParameterErr, FixParameterLbl);
        Entry.Add('refusal', 'InvalidParameter');
        Errors.Add(Entry);
        Entry := ContractMgt.ErrorEntry("Bifrost Error Code ori"::BusinessCentralError, NativeErrorLbl, FixNativeLbl);
        Entry.Add('refusal', 'BusinessCentralError');
        Errors.Add(Entry);
        exit(true);
    end;

    /// <summary>Declares read-only effects, permissions and preconditions.</summary>
    procedure GetEffect(var Effect: JsonObject): Boolean
    var
        Preconditions: JsonArray;
    begin
        Clear(Effect);
        Effect.Add('effect', 'read');
        Effect.Add('writes', false);
        Effect.Add('posts', false);
        Effect.Add('changes', ChangesLbl);
        Effect.Add('idempotent', true);
        Effect.Add('permissionSet', 'BIFROST SustRead ori');
        Preconditions.Add(PermissionLbl);
        Effect.Add('preconditions', Preconditions);
        exit(true);
    end;

    /// <summary>No additional metering contract is required.</summary>
    procedure GetMetering(var Metering: JsonObject): Boolean
    begin
        Clear(Metering);
        exit(false);
    end;

    /// <summary>No additional related contract is required.</summary>
    procedure GetRelated(var Related: JsonArray): Boolean
    begin
        Clear(Related);
        exit(false);
    end;

    /// <summary>No additional workflow contract is required.</summary>
    procedure GetWorkflow(var Workflow: JsonObject): Boolean
    begin
        Clear(Workflow);
        exit(false);
    end;

    /// <summary>Provides a credential-free demo request.</summary>
    procedure GetExamples(var Examples: JsonArray): Boolean
    var
        ContractMgt: Codeunit "Msg Contract Mgt ori";
    begin
        Clear(Examples);
        Examples.Add(ContractMgt.Example(ExampleLbl,
            '{"type":"Sustainability.AccountBalance.Get","data":{"accountNo":"1000","includeZero":true}}',
            '{"status":"Success","accounts":[{"no":"1000","name":"Emissions","accountType":"Posting","indentation":0,"netChange":{"co2":0,"ch4":0,"n2o":0,"co2e":0,"water":0,"dischargedWater":0,"waste":0},"balance":{"co2":0,"ch4":0,"n2o":0,"co2e":0,"water":0,"dischargedWater":0,"waste":0}}]}'));
        exit(true);
    end;

    /// <summary>Explains the account read.</summary>
    procedure GetOverview(var Overview: Text): Boolean
    begin
        Overview := DescriptionLbl;
        exit(true);
    end;

    /// <summary>Explains totals, dates, visibility and transaction effects.</summary>
    procedure GetNotes(var Notes: Text): Boolean
    begin
        Notes := NotesLbl;
        exit(true);
    end;
}
