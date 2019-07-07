param (
    [Parameter(Mandatory=$true)]
    [String]
    $Filename
)

function Invoke-Exiftool([Parameter(Mandatory=$true)][String]$Filename, $ExiftoolPath)
{
    if ($null -eq $ExiftoolPath)
    {
        # assume in path
        $ExiftoolPath = 'exiftool.exe';
    }

    $args = @($Filename);
    $output = & $ExiftoolPath $args;
    return $output;
}

function Get-Exif([Parameter(Mandatory=$true)][String]$Filename)
{
    $exiftoolOutput = Invoke-Exiftool -Filename $Filename
    $lineByLine = $exiftoolOutput -split "`r`n";
    $result = @{};
    foreach ($line in $lineByLine)
    {
        $keyValue = $line -split "\s+:\s+";
        $result[$keyValue[0]] = $keyValue[1];
    }

    return $result;
}

if (-not (Test-Path $Filename))
{
    Write-Error "File not found $Filename";
    return 1;
}

$exif = Get-Exif -Filename $Filename

$projection = $exif['Panoramic Stitch Map Type'];
if ($projection -ne 'Horizontal Cylindrical')
{
    Write-Error "Only horizontal cylindrical projections are supported";
    return 2;
}

$hStart = [double]($exif['Panoramic Stitch Theta 0']);
$hEnd = [double]($exif['Panoramic Stitch Theta 1']);
$vStart = [double]($exif['Panoramic Stitch Phi 0']);
$vEnd = [double]($exif['Panoramic Stitch Phi 1']);

$imageHeight = [int]($exif['Image Height']);
$imageWidth = [int]($exif['Image Width']);

if (($imageHeight -gt 30000) -or ($imageWidth -gt 30000))
{
    Write-Error "Please, resize the image to be less than 30000 on any dimension (current: $($imageWidth)x$($imageHeight))";
    return 3;
}

if ($imageHeight * $imageWidth -gt 135000000)
{
    Write-Error "Image must have less than 135 M pixels";
    return 4;
}

$pi = [System.Math]::PI;
$hSpan = [System.Math]::Abs($hEnd - $hStart);
$vSpan = [System.Math]::Abs($vEnd - $vStart);

$fullPanoImageWidth = [int]($imageWidth / $hSpan * (2 * $pi));
$fullPanoImageHeight = [int]($imageHeight / $vSpan * $pi); # cylindrical projection vertical span is 180 degrees

Write-Output "fw: $fullPanoImageWidth; fh: $fullPanoImageHeight";

# we'll discard calculated height for now and set it exactly to half width as FB expects
$fullPanoImageHeight = [int]($fullPanoImageWidth / 2);

Write-Output "After correction fw: $fullPanoImageWidth; fh: $fullPanoImageHeight";

$hStartPixels = [int][System.Math]::Round($hStart / (2 * $pi) * $fullPanoImageWidth);
$hSpanPixels = [int][System.Math]::Round($hSpan / (2 * $pi) * $fullPanoImageWidth);

$vStartPixels = [int][System.Math]::Round($vStart / $pi * $fullPanoImageHeight);
$vSpanPixels = [int][System.Math]::Round($vSpan / $pi * $fullPanoImageHeight);

$commandLine = "exiftool -FullPanoWidthPixels=$fullPanoImageWidth -FullPanoHeightPixels=$fullPanoImageHeight -CroppedAreaLeftPixels=$hStartPixels -CroppedAreaTopPixels=$vStartPixels -CroppedAreaImageWidthPixels=$hSpanPixels -CroppedAreaImageHeightPixels=$vSpanPixels -ProjectionType=cylindrical $Filename";

Write-Output $commandLine
$commandLine | Set-Clipboard