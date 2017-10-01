#
# Author: https://github.com/neolithos
#
# Licensed under the EUPL, Version 1.1 or - as soon they will be approved by the
# European Commission - subsequent versions of the EUPL(the "Licence"); You may
# not use this work except in compliance with the Licence.
#
# You may obtain a copy of the Licence at:
# http://ec.europa.eu/idabc/eupl
#
# Unless required by applicable law or agreed to in writing, software distributed
# under the Licence is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR
# CONDITIONS OF ANY KIND, either express or implied. See the Licence for the
# specific language governing permissions and limitations under the Licence.
#

Add-Type -AssemblyName "System.IO.Compression, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089";
Add-Type -AssemblyName "System.IO.Compression.FileSystem, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089";

function New-ScsMod(
	[string]$RootPath,
	[string]$Name,
	[bool]$Steam,
	[bool]$ETS = $false,
	[string[]]$Content
) 
{
	function compressFile([System.IO.Compression.ZipArchive]$zip, [string]$fullSource, [int]$entryOffset, [bool]$noCompression) {

		$entryName = $fullSource.Substring($entryOffset).Replace("\", "/");
		Write-Host "  $($entryName)";
		if ($noCompression) {
			$_ = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $fullSource, $entryName, [System.IO.Compression.CompressionLevel]::NoCompression);
		} else {
			$_ = [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $fullSource, $entryName);
		}
	} # compressFile

	# paths
	$binDirectory = Join-Path $RootPath "bin";
	$targetZip = Join-Path $binDirectory "$name.zip";
	$targetSteam = Join-Path $binDirectory "steam";

	# remove current files
	New-Item -Path $binDirectory -ItemType Directory -ErrorAction SilentlyContinue;
	Remove-Item -Recurse $targetZip -ErrorAction SilentlyContinue
	Remove-Item -Recurse $targetSteam -ErrorAction SilentlyContinue

	# create zip file
	Write-Host "Create Zip: $($name)";
	$zip = [System.IO.Compression.ZipFile]::Open($targetZip, [System.IO.Compression.ZipArchiveMode]::Create);
	try {
		$ofs = $RootPath.Length + 1;
		foreach ($sub in $Content) {

			# check for compression flag
			$noCompression = $sub.StartsWith("|");
			if ($noCompression) {
				$sub = $sub.Substring(1);
			}
	
			$fullPath = Join-Path $RootPath $sub;

			if (Test-Path -PathType Leaf -Path $fullPath) { # check for file
		
				compressFile $zip $fullPath $ofs $noCompression;

			} elseif (Test-Path -PathType Container -Path $fullPath) { # add directory

				foreach ($fi in Get-ChildItem -Recurse $fullPath) {
					if (Test-Path -PathType Leaf $fi.FullName) {
						compressFile $zip $fi.FullName $ofs $noCompression;
					}
				}

			}
		}
	}
	finally {
		$zip.Dispose();
	}

	# copy to mod folder
	if($ETS) {
		$gameType = "European Truck Simulator"
	} else {
		$gameType = "American Truck Simulator"
	}
	Write-Host "Copy Mod: $($home), $($gameType)";
	Copy-Item $targetZip -Destination (Join-Path $home "Documents\$gameType\mod\$name.scs");

	# prepare steam upload
	if ($Steam) {

		Write-Host "Prepare Steam upload...";
		$fi = New-Object -TypeName System.IO.FileInfo -ArgumentList (Join-Path $targetSteam "universal.zip");
		if (!($fi.Directory.Exists)) {
			$fi.Directory.Create();
		}

		Copy-Item $targetZip -Destination $fi.FullName;
		Copy-Item (Join-Path $RootPath versions.sii) -Destination $targetSteam;
	}
} # Pack-ScsMod