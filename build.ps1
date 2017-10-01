Import-Module .\build_scs.psm1

New-ScsMod -Name kenworth_w900_dashboard_neo -RootPath $PSScriptRoot -Steam $true -Content @(
	"icon.jpg",
	"manifest.sii",
	"mod_description.txt",

	"ui",
	"material"
);
