include "common" ;
( "#!/usr/bin/env bash\n" )
+ "\n" +
(
    "_BM_ENVIRONMENT_NAME_=" + (.name | @sh) + "\n"
)
+ "\n" +
(
    [ .values[] |
        ( if .enabled then "" else "#" end)
            + ( (.key | to_var)
                + "="
                + (.value | @sh)
              )
    ] | join("\n")
)
