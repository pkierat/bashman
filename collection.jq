include "common" ;
(
    .info
        | ( ""
          + "BM_COLLECTION_NAME=" + (.name | @sh) + "\n"
          + "BM_COLLECTION_SCHEMA=" + (.schema | @sh) + "\n"
          )
)
+ "\n" +
(
    (if .auth.type == "basic" then
        ""
        + "BM_AUTH_TYPE=" + ("basic" | quote) + "\n"
        + "BM_AUTH_USER=" + (.auth.basic[] | select(.key == "username") | .value | vars | quote) + "\n"
        + "BM_AUTH_PASS=" + (.auth.basic[] | select(.key == "password") | .value | vars | quote) + "\n"
     else
        empty
     end)
)
+ "\n" +
(
    [ .item[]
        | (( .name | to_fun) + "() {\n"
            + ([
                "    BM_NAME=" + (.name | quote),
                "    BM_METHOD=" + (.request.method | quote),
                "    BM_HEADER=" + "(" + ([.request.header[] | "[" + .key + "]=" + (.value | @sh)] | join(" ")) + ")",
                if .request | has("body") then
                    "    BM_BODY=$(cat <<-END_OF_BODY\n\(((.request.body.raw | vars) + "\nEND_OF_BODY\n") | tab))"
                else
                    empty
                end,
                "    BM_URL=" + (.request.url.raw | vars | quote)
               ] | join("\n") + "\n")
            + ("}\n")
        )
    ] | join("\n")
)
