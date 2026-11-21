namespace Origo.Bifrost.Sustainability;

/// <summary>
/// Permission marker for Sustainability.Goal.Set. The table stores no business rows; only BIFROST SustFull ori grants it,
/// so the Full grant is enforced even where Foundation API roles grant wildcard codeunit execution.
/// </summary>
table 70009212 "Sust Goal Set Access ori"
{
    Access = Internal;
    Caption = 'Sustainability goal write access', Comment = 'is-IS=Aðgangur að ritun sjálfbærnimarkmiða';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary key', Comment = 'is-IS=Aðallykill';
        }
    }

    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
