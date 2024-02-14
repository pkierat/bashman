def to_var: ascii_upcase | gsub("-" ; "_") ;
def vars: gsub("{{(?<var>[A-Za-z0-9-_]+)}}" ; "${\(.var | to_var)}") ;
def to_fun: ascii_downcase | gsub("[ -/]" ; "_") ;
def tab: sub("^" ; "\t") | gsub("\n" ; "\n\t") ;
def quote: "\"" + . + "\"" ;
