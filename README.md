# ice2fb
A powershell script to help producing Facebook compatible panoramas from [Image Composite Editor](https://www.microsoft.com/en-us/research/product/computational-photography-applications/image-composite-editor/)

Expects an [`exiftool`](https://sno.phy.queensu.ca/~phil/exiftool/) executable to be available
through the `PATH` environment variable.

Export panorama as JPEG from ICE using the cylindrical projection. Run the script:

```
fbpano.ps1 -Filename <path to your panorama.jpg>
```

The script will output (and copy to the clipboard) the command line arguments for the `exiftool`
that when run would update your image to make it compatible with [Facebook 360](https://facebook360.fb.com).

It does not to change the image, you have to run the provided command yourself.

## Documentation
 * https://facebook360.fb.com/editing-360-photos-injecting-metadata/
 * https://developers.google.com/streetview/spherical-metadata
 * https://developers.facebook.com/docs/graph-api/reference/photo/ - search for `spherical_metadata`
parameter then click the down arrow to expand the documentation.