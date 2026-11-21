namespace Origo.Bifrost.Sustainability;

/// <summary>Permission marker for journal preview. No records are stored.</summary>
table 70009215 "Sust Preview Access ori"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    Caption = 'Sustainability preview access', Comment = 'is-IS=Aðgangur að forskoðun sjálfbærni';
    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.', Comment = 'is-IS=Færslunr.';
        }
    }
    keys
    {
        key(PK; "Entry No.")
        {
            Clustered = true;
        }
    }
}
