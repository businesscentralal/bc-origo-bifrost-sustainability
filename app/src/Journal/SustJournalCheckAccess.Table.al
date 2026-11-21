namespace Origo.Bifrost.Sustainability;

/// <summary>Permission marker for journal check. No records are stored.</summary>
table 70009214 "Sust Journal Check Access ori"
{
    Access = Internal;
    DataClassification = SystemMetadata;
    Caption = 'Sustainability check access', Comment = 'is-IS=Aðgangur að athugun sjálfbærni';
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
