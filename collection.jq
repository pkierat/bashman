include "common" ;
def leaf($name):
    $name + "() {\n" + ([
        "    BM_NAME=" + (.name | quote),
        "    BM_METHOD=" + (.request.method | quote),
        "    BM_HEADER=" + ("(" + ([.request.header[] | ((.key + ": " + .value) | vars | quote)] | join(" ")) + ")"),
        if .request | has("body") then
            "    BM_BODY=$(cat <<-END_OF_BODY\n\(((.request.body.raw | vars) + "\nEND_OF_BODY\n") | tab))"
        else
            empty
        end,
        "    BM_URL=" + (.request.url.raw | vars | quote)
       ] | join("\n") + "\n")
    + ("}\n");
def item($prefix):
    if .item == null then
        . | leaf($prefix)
    else
        .item[] | item($prefix + ":" + (.name | to_fun))
    end;
( "#!/usr/bin/env bash\n" )
+ "\n" +
(
    .info
        | ( ""
          + "BM_COLLECTION_NAME=" + (.name | @sh) + "\n"
          + "BM_COLLECTION_DESCRIPTION=" + (.description | @sh) + "\n"
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
     elif .auth.type == "digest" then
        ""
        + "BM_AUTH_TYPE=" + ("digest" | quote) + "\n"
        + "BM_AUTH_USER=" + (.auth.digest[] | select(.key == "username") | .value | vars | quote) + "\n"
        + "BM_AUTH_PASS=" + (.auth.digest[] | select(.key == "password") | .value | vars | quote) + "\n"
     elif .auth.type == "bearer" then
        ""
        + "BM_AUTH_TYPE=" + ("apikey" | quote) + "\n"
        + "BM_AUTH_TOKEN=" + (.auth.bearer[] | select(.key == "token") | .value | vars | quote) + "\n"
     elif .auth.type == "apikey" then
        ""
        + "BM_AUTH_TYPE=" + ("apikey" | quote) + "\n"
        + "BM_AUTH_KEY=" + (.auth.apikey[] | select(.key == "key") | .value | vars | quote) + "\n"
        + "BM_AUTH_VALUE=" + (.auth.apikey[] | select(.key == "value") | .value | vars | quote) + "\n"
     else
        ""
     end)
)
+ "\n" +
([ .item[] | item(.name | to_fun) ] | join("\n"))
