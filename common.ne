@builtin "whitespace.ne" # `_` means arbitrary amount of whitespace

metar -> obId ICAO ddhhmmZ Wind viswx skycon tempdewpt obAlt {% 
	function(d,l,reject) {
		return {
			type: d[0],
			station: d[1],
			time: d[2],
			wind: d[3],
			viswx: d[4],
			cloud: d[5],
			temp: d[6],
			alstg: d[7]
		};
	}
%}

#wind values
Wind -> direction speed gust:? speedunit __ {%
		function(d,l,reject) {
			if (d[2] && d[2]<d[1]) {
				return reject;
			}
			return {
				dir: d[0],
				spd: d[1],
				gst: d[2],
				unit: d[3]
			};
		}
	%}
	| "M" __ {% ()=>(null) %}
direction ->digit2 "0" {% ([fst, _],l,r) => fst <36 ? fst*10 : r %}
	| "VRB" {% id %}
speed -> digit2 {% id %} | nzdigit3 {% id %}
gust -> "G" speed {% ([_,speed]) => speed %}
speedunit -> "KT" {% id %} | "MPS" {% id %}

# times
ddhhmmZ -> ddhhmm "Z" __ {% ([t,_]) => t %}

ddhhmm -> digit2 digit2 digit2 {% 
	function(d,l,reject) {
		if (d[0] > 31 || d[1] > 23 || d[2] > 59) {
			return reject;
		}
		return {
			day: d[0],
			hour: d[1],
			min: d[2]
		};
	}
%}

# viswx

viswx -> vis wx:? {% ([v,w]) => ({vis:v, wx:w})%}

vis -> vissm __ {% ([v]) => ({range: v, unit: "SM"})%}
	| "M" __ {% ()=>(null) %}

vissm -> digit2 "SM" {% id %}
	| digit "SM" {% (d) => d[0][0] %}
	| digit __ fraction "SM" {% ([m,_,f]) => (m|0)+f %}
	| fraction "SM" {% id %}
	
wx -> "BR" __

pwxtor -> "+":? "FC" __ 

pwsts -> "TS" wxprecip wxprecip:? wxprecip:? __ 

wxint -> "-" | "+" | null | "VC"

wxdesc -> "SH" | "TS" | "FZ" | "BL"

wxprecip -> "DZ" | "RA" | "SN" | "SG" | "IC" | "PL" | "GR" | "GS"

# clouds

skycon -> "SKC" __ {% () => [{coverage: "SKC", okta: 0, height: 0}] %}
	| "CLR" __ {% () => [{coverage: "CLR", okta: 0, height: 0}] %}
	| "VV" height __{% ([c,h]) => [{coverage: "VV", okta: 8, height: h}] %}
	| cldlyr:+ {% id %}
	| "M" __ {% ()=>(null) %}

cldlyr -> cldcov height __ {% ([cov,hgt,_])=> ({coverage: cov.cov, okta:cov.okta, height: hgt}) %}

cldcov -> "FEW" {% ([d]) => ({cov: d, okta:1}) %}
	| "SCT" {% ([d]) => ({cov: d, okta:3}) %}
	| "BKN" {% ([d]) => ({cov: d, okta:5}) %}
	| "OVC" {% ([d]) => ({cov: d, okta:8}) %}

height -> digit3 {% id %}

ICAO -> alpha alphanum alphanum alphanum __ {% (d) => d.join("") %}

# temp

tempdewpt -> temp "/" temp __ {% ([t,s,d,_],l,r) => (t<d?r:{temp:t, dewpt:d}) %}

temp -> digit2 {% id %}
	| "M" digit2 {% ([m,t]) => -t %}
	
# altimeter

obAlt -> "A" digit4 __{% (d) => ({stg: d[1]/100, unit: "inHg"}) %}
	| "Q" digit4 __{% (d) => ({stg: d[1], unit: "mb"}) %}

# line starter

obId -> "METAR" __ {% id %} | "SPECI" __ {% id %}

# common
alphanum -> alpha | digit
alpha -> [a-zA-Z]
nonzero -> [1-9]
digit -> [0-9] 
digit2 -> digit digit {% (d) => d.join("")|0 %}
digit3 -> digit digit digit {% (d) => d.join("")|0 %}
digit4 -> digit digit digit digit {% (d) => d.join("")|0 %}
nzdigit3 -> nonzero digit digit {% (d) => d.join("")|0 %}
fraction -> digit "/" ("2"|"4"|"8"|"16") {% ([n,s,d],l,r) => n<d?n[0]/d[0]:r %}
