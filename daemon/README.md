# retronasd

This is *(future work on)* a daemon manager for retronas, ultimately seperating retronas from the UI.

**Please Note:** this is entirely theoretical at the moment and may end up being completely different than what is documented below.

## Context seperation
* retronasd runs as priviledged user
* UI runs as unprivileged user

`DIR_SPOOL=/var/spool/retronas`
`DIR_CACHE=/var/cache/retronas

## Workflow
The expected workflow is theorised as ...

### retronasd
1. retronasd run as a daemon through sys(v|temd)/supervisord etc
1. retronasd watches `DIR_SPOOL` for changes
1. retronasd detects changed content in `DIR_SPOOL`
1. retronasd ingests content of `DIR_SPOOL` and takes requested actions based on valid keywords
1. retronasd communicates progress to UI
1. retronasd updates cache in `DIR_CACHE`

### user
1. User accesses a UI
1. User selects a UI element, triggering an action (i.e Install Samba)
1. UI drops a file to `DIR_SPOOL`


