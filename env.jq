include "common" ;
(
    "BM_ENV_NAME=" + (.name | @sh) + "\n"
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
