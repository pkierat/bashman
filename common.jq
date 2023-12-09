def to_var: ascii_upcase | gsub("-" ; "_") ;
def vars: gsub("{{(?<var>[a-z0-9-]+)}}" ; "${\(.var | to_var)}") ;
def to_fun: ascii_downcase | gsub("[ -/]" ; "_") ;
def tab: sub("^" ; "\t") | gsub("\n" ; "\n\t") ;
def quote: "\"" + . + "\"" ;
