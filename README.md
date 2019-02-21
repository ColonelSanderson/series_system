
# series_system

Developed by Hudson Molonglo in collaboration with GAIA Resources and Recordkeeping Innovation
as part of the Queensland State Archives Digital Archiving Program.

## Dependancies

### External IDs

To expose External IDs on relevant Series system records (and other
ArchivesSpace records), add the following configuration:
```
AppConfig[:show_external_ids] = true
```

To allow External IDs to be editable, use this plugin in conjunction with the
`editable_external_ids` plugin available here:

* https://github.com/hudmol/editable_external_ids
