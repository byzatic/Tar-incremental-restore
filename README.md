# Tar incremental restore
## version 1.0.2

**RESTORE_PERIOD=Nd:Nw:Nm:Ny or "all" or ""** - Period for restore. The format is flexible and supports any combination of Nd:Nw:Nm:Ny, even if values are repeated. If you set ‘all’, it means restoring for the entire available period. Alternatively, use an empty string ("") to fallback to RESTORE_FROM.

**RESTORE_FROM="YYYY-MM-DD" or ""** - restore from date in YYYY-MM-DD or empty ""

P.S.: RESTORE_FROM or RESTORE_PERIOD should be defined. RESTORE_PERIOD is more privileged than RESTORE_FROM.

**STRIP_COMPONENTS=N** - (optional variable, default STRIP_COMPONENTS=1) - option in tar is used to remove a specified number (N) of leading directory components from extracted file.