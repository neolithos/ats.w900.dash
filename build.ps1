
$rootPath = "D:\ATS\kenworth_w900_dashboard";
$compress = @(
	"icon.jpg",
	"manifest.sii",
	"mod_description.txt"
);

$compressSubs = @(
	"ui",
	"material"
)

$ofs = $rootPath.Length + 1;
foreach ($sub in $compressSubs) {
	foreach ($fi in Get-ChildItem -Recurse (Join-Path $rootPath $sub)) {
		if (Test-Path -PathType Leaf $fi.FullName) {
			$compress += $fi.FullName.Substring($ofs);
		}
	}
}

$targetZip = Join-Path $rootPath .\bin\kenworth_w900_dashboard_neo.zip;
$targetSteam = Join-Path $rootPath .\bin\steam
Remove-Item -Recurse $targetZip -ErrorAction SilentlyContinue
Remove-Item -Recurse $targetSteam -ErrorAction SilentlyContinue

$zip = [System.IO.Compression.ZipFile]::Open($targetZip, [System.IO.Compression.ZipArchiveMode]::Create);

Write-Host "Pack:";
foreach ($cur in $compress) {

	if ($cur.EndsWith("/")) {
		Write-Host $cur;
		$_ = $zip.CreateEntry($cur, [System.IO.Compression.CompressionLevel]::NoCompression);
	} else {
		$fullSource = Join-Path $rootPath $cur;

        # zip
		$entryName = $cur.Replace("\", "/");
		Write-Host $entryName;
		$_ = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $fullSource, $entryName);

        # steam
        #$fi = New-Object -TypeName System.IO.FileInfo -ArgumentList (Join-Path (Join-Path $targetSteam "universal") $cur);
        #if (!($fi.Directory.Exists)) {
        #    $fi.Directory.Create();
        #}
        #Copy-Item $fullSource $fi.FullName;
	}
}

$zip.Dispose();

Copy-Item $targetZip -Destination "C:\Users\Stein\Documents\American Truck Simulator\mod\kenworth_w900_dashboard_neo.scs"

$fi = New-Object -TypeName System.IO.FileInfo -ArgumentList (Join-Path $targetSteam "universal.zip");
if (!($fi.Directory.Exists)) {
    $fi.Directory.Create();
}
Copy-Item $targetZip -Destination $fi.FullName;
Copy-Item .\versions.sii -Destination $targetSteam;