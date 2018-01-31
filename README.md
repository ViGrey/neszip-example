# neszip Example

An NES ROM that is also a ZIP file that contains its own source code to make a new NES+ZIP file

**_neszip Example is created by Vi Grey (https://vigrey.com) <vi@vigrey.com> and is licensed under the BSD 2-Clause License.  Read LICENSE for license text._**

#### Description:

This neszip example will create an NES ROM file that is also a ZIP file that contains its own source code.  Using the source code to build a the NES ROM file will also embed the ZIP file within it as well, making another NES ROM file that is also a ZIP file that contains its own source code.  This is a recursive NES ROM and ZIP polyglot file.

The NES ROM can be burned onto a cartridge and it will still work as an NES game while retaining the ZIP file, so if the NES ROM is ripped from the cartridge, that resulting NES ROM file would also be a ZIP file.

#### Platforms:
- GNU/Linux

#### Build Dependencies:
- asm6 _(You'll probably have to build asm6 from source.  The source code can be found at http://3dscapture.com/NES/asm6.zip)_
- zip
- Python 3

#### Extraction Dependencies:

- unzip

#### Build NES ROM:

From a terminal, go to the the main directory of this project (the directory this README.md file exists in), you can then build the NES ROM with the following command.

    $ make

The resulting NES ROM will be located at **bin/neszip-example.nes**

#### Cleaning Build Environment:

If you used `make` to build the NES ROM, you can run the following command to clean up the build environment.

    $ make clean

#### Unzipping the ROM:

Your zip file extractor should be able to extract this file, although you may have to change the extension from **.nes** to **.zip** to make your zip file extractor work.
