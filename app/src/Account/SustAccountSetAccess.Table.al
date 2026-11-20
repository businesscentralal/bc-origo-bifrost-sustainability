namespace Origo.Bifrost.Sustainability;

/// <summary>
/// Capability of Sustainability.Account.Set, granted only by BIFROST SustFull ori. Stores no records.
/// Foundation's API role executes every codeunit, so the write permission on this table is what the type checks.
/// </summary>
table 70009210 "Sust Account Set Access ori"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    Caption = 'Sustainability account maintenance', Comment = 'is-IS=Viðhald sjálfbærnireikninga';

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key', Comment = 'is-IS=Aðallykill';
        }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}
