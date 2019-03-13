
# series_system

Developed by Hudson Molonglo in collaboration with GAIA Resources and Recordkeeping Innovation
as part of the Queensland State Archives Digital Archiving Program.

## Hiding fields

To hide fields using the  `assets/config/hidden_fields.json` config, add a new entry for the controller type (eg. `agents`), then using the id of the `<section>` element, add a new property (eg. `agent_corporate_entity_names`) with `show` and `defaultValues` arrays.
Entries in the `show` array are the segments of the id that are generated using its data-attributes. An empty array here indicates that all values should be hidden, as will the section header and if applicable, the menu sidebar link.
`defaultValues` entries are objects with a path array, and a value.
It should look something like this: 
```json
{
  "agents": {
    "agent_corporate_entity_names": {
      "show": [
        ["agent_names_", "_authority_id_"],
        ["agent_names_", "_source_"],
        ["agent_names_", "_rules_"]
      ],
      "defaultValues": [
        { "path": ["agent_names_", "_source_"], "value": "local" }
      ]
    }
  }
}
```
Once an entry is added, that section's fields will be hidden unless they have been added to `show` array.
For hiding fields in sub-sections, an entry will need to be added for both the `<section>` id and the field in the parent `<section>`.

The `defaultValues` property allows fields have have mandatory values added to them when hidden.


## Dependencies

### External IDs

To expose External IDs on relevant Series system records (and other
ArchivesSpace records), add the following configuration:
```
AppConfig[:show_external_ids] = true
```

To allow External IDs to be editable, use this plugin in conjunction with the
`editable_external_ids` plugin available here:

* https://github.com/hudmol/editable_external_ids
