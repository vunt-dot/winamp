# Winamp

## About

Winamp is a multimedia player launched in 1997, iconic for its flexibility and wide compatibility with audio formats. Originally developed by Nullsoft, it gained massive popularity with still millions of users. Its development slowed down, but now, its source code was opened to the community, allowing developers to improve and modernize the playerto meet current user needs.

## Usage

Building of the Winamp desktop client is current based around Visual Studio 2019 (VS2019) and Intel IPP libs (You need to use exactly v6.1.1.035).
There are differnt options of how to build Winamp:

1. Use a build_winampAll_2019.cmd script file that makes 4 versions x86/x64 (Debug and Release). In this case Visual Studio IDE not running.
2. Use a winampAll_2019.sln file to build and debug in Visual Studio IDE.

### Dependencies

#### libvpx
We take libvpx from https://github.com/ShiftMediaProject/libvpx, modify it and pack to archive.
Run unpack_libvpx_v1.8.2_msvc16.cmd to unpack.

#### libmpg123
We take libmpg123 from https://www.mpg123.de/download.shtml, modify it and pack to archive.
Run unpack_libmpg123.cmd to unpack and process dlls.

#### OpenSSL
You need to use openssl-1.0.1u. For that you need to build a static version of these libs.
Run build_vs_2019_openssl_x86.cmd and build_vs_2019_openssl_64.cmd.

To build OpenSSL you need to install

7-Zip, NASM and Perl.

#### DirectX 9 SDK 
We take DirectX 9 SDK (June 2010) from Microsoft, modify it and pack to archive.
Run unpack_microsoft_directx_sdk_2010.cmd to unpack it.

#### Microsoft ATLMFC lib fix
In file C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Tools\MSVC\14.24.28314\atlmfc\include\atltransactionmanager.h

goto line 427 and change from 'return ::DeleteFile((LPTSTR)lpFileName);' to 'return DeleteFile((LPTSTR)lpFileName);'

#### Intel IPP 6.1.1.035
We take Intel IPP 6.1.1.035, modify it and pack to archive.
Run unpack_intel_ipp_6.1.1.035.cmd to unpack it.

## Default skin and high DPI (this fork)

- The default skin is the classic `base-2.91.wsz`, shipped in `Src/resources/skins/`. Both the post-build step and the installer copy every `*.wsz` in that folder into Winamp's `Skins` folder.
- To also ship **Winamp5 Classified v5.5**, download it from https://skins.webamp.org/skin/b0fb83cc20af3abe264291bb17fb2a13/Winamp5_Classified_v5.5.wsz/ and save it as `Src/resources/skins/Winamp5_Classified_v5.5.wsz` before building. Switch skins with right-click → Skins, or Alt+S.
- High DPI and 4K: `winamp.exe` is DPI-aware, so Windows doesn't blur it. On a fresh install with display scaling of 150% or more, the main window and EQ start in double size (Ctrl+D toggles it). That pixel-doubles classic skins so they look sharp. The x64 build now embeds `manifest64.xml` as well.
- Build steps: install VS2019 with the v142 toolset and Windows SDK 10.0.19041, set up the dependencies above, then run `Src\winampAll\build_winampAll_2019.cmd` or build `winampAll_2019.sln`. Use the **Release|Win32** (x86) build: the x64 build has no modern-skin (Bento) support. Output goes to `Build\Winamp_x86_Release\`.

## Ubuntu 24.04 / 26.04 (.deb via Wine)

Winamp is a Windows program, so the Linux package runs the Windows build under Wine. The same `.deb` works on both Ubuntu releases.

1. Build Winamp on Windows (see above), then copy `Build\Winamp_x86_Release\` to the Linux machine.
2. Build the package: `packaging/linux/build-deb.sh path/to/Winamp_x86_Release` → `winamp_5.9.2-1_all.deb`
3. Install it:
   ```sh
   sudo dpkg --add-architecture i386 && sudo apt update   # 32-bit Wine for the x86 build
   sudo apt install wine wine32:i386 ./winamp_5.9.2-1_all.deb
   ```
4. Run `winamp` or open it from the app menu. Settings go in `~/.local/share/winamp/prefix`.

On first launch, the launcher reads the desktop scaling (`Xft.dpi`, or GNOME's scaling factor) and passes it to Wine. At 150% scaling or more, Winamp then starts in double size. To override the detected value, run `WINAMP_DPI=192 winamp` (96 = 100%, 144 = 150%, 192 = 200%).
