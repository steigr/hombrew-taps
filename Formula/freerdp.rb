class Freerdp < Formula
  desc "X11 implementation of the Remote Desktop Protocol (RDP)"
  homepage "https://www.freerdp.com/"

  url "https://github.com/FreeRDP/FreeRDP/releases/download/3.17.2/freerdp-3.17.2.tar.gz"
  sha256 "c42c712ad879bf06607b78b8c3fad98e08c82f73f4e0bc1693552900041e692a"
  license "Apache-2.0"

  head do
    url "https://github.com/FreeRDP/FreeRDP.git", branch: "master"
    depends_on xcode: :build
  end

  depends_on "cmake" => :build
  depends_on "pkgconf" => :build
  depends_on "cjson"
  depends_on "ffmpeg"
  depends_on "jpeg-turbo"
  depends_on "libusb"

  # depends_on "libx11"
  # depends_on "libxcursor"
  # depends_on "libxext"
  # depends_on "libxfixes"
  # depends_on "libxi"
  # depends_on "libxinerama"
  # depends_on "libxrandr"
  # depends_on "libxrender"
  # depends_on "libxv"

  depends_on "openssl@3"
  depends_on "pkcs11-helper"
  depends_on "sdl3"
  depends_on "sdl3_ttf"

  uses_from_macos "cups"
  uses_from_macos "zlib"

  on_linux do
    depends_on "alsa-lib"
    depends_on "glib"
    depends_on "icu4c@77"
    depends_on "krb5"
    depends_on "libfuse"
    depends_on "systemd"
    depends_on "wayland"
  end

  def install
    args = %W[
      -DBUILD_SHARED_LIBS=ON
      -DCMAKE_INSTALL_NAME_DIR=#{lib}
      -DWITH_X11=OFF
      -DWITH_JPEG=ON
      -DWITH_MANPAGES=OFF
      -DWITH_WEBVIEW=OFF
      -DWITH_CLIENT_SDL=ON
      -DWITH_CLIENT_SDL2=OFF
      -DWITH_CLIENT_SDL3=ON
      -DWITH_CHANNELS=ON
      -DCHANNEL_RDP2TCP=ON
      -DCHANNEL_GFXREDIR=ON
      -DCHANNEL_GEOMETRY=ON
      -DCHANNEL_RDPGFX=ON
      -DCHANNEL_SSHAGENT=ON
      -DCHANNEL_VIDEO=ON
      -DCHANNEL_RDPEMSC=ON
      -DCHANNEL_RDPECAM=ON
      -DCHANNEL_RDPEAR=ON
      -DCHANNEL_RDPDR=ON
      -DCHANNEL_RAIL=ON
      -DCHANNEL_LOCATION=ON
      -DCHANNEL_DRIVE=ON
      -DCHANNEL_DRDYNVC=ON
      -DCHANNEL_DISP=ON
      -DCHANNEL_CLIPRDR=ON
      -DCHANNEL_AUDIN=ON
      -DCHANNEL_AINPUT=ON
    ]

    # Native macOS client and server implementations are unmaintained and use APIs that are obsolete on Sequoia.
    # Ref: https://github.com/FreeRDP/FreeRDP/issues/10558
    if OS.mac? && MacOS.version >= :sequoia
      # As a workaround, force X11 shadow server implementation. Can use -DWITH_SHADOW=OFF if it doesn't work
      inreplace "server/shadow/CMakeLists.txt", "add_subdirectory(Mac)", "add_subdirectory(X11)"

      args += ["-DWITH_CLIENT_MAC=OFF", "-DWITH_PLATFORM_SERVER=OFF"]
    end

    system "cmake", "-S", ".", "-B", "build", *args, *std_cmake_args
    system "cmake", "--build", "build"
    system "cmake", "--install", "build"
  end

  def caveats
    extra = ""
    <<~EOS
      xfreerdp is an X11 application that requires an XServer be installed
      and running. Lack of a running XServer will cause a "$DISPLAY" error.
      #{extra}
    EOS
  end

  test do
    return if OS.linux? && ENV["HOMEBREW_GITHUB_ACTIONS"]

    success = `#{bin}/xfreerdp --version` # not using system as expected non-zero exit code
    details = $CHILD_STATUS
    raise "Unexpected exit code #{$CHILD_STATUS} while running xfreerdp" if !success && details.exitstatus != 128
  end
end
