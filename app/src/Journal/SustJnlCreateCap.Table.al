namespace Origo.Bifrost.Sustainability;

/// <summary>Empty capability table: only the Full role grants read access. No rows are created.</summary>
table 70009213 "Sust Jnl Create Cap ori"
{
    Access = Internal;
    Caption = 'Create sustainability journal', Comment = 'is-IS=Stofna sjálfbærnibók';
    DataClassification = SystemMetadata;
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
