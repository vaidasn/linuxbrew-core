class Glib < Formula
  desc "Core application library for C"
  homepage "https://developer.gnome.org/glib/"
  url "https://download.gnome.org/sources/glib/2.64/glib-2.64.2.tar.xz"
  sha256 "9a2f21ed8f13b9303399de13a0252b7cbcede593d26971378ec6cb90e87f2277"
  revision 1

  bottle do
    sha256 "b8e8a0f1229f7094233832516f5aad725c1447a74cc1ca342b69da9b7a5aed9f" => :catalina
    sha256 "4ac9833acd0b2e6f8aa81bc426db78bcf2f4783f4788006d329d65c29b1bc561" => :mojave
    sha256 "b01fb6863b96a8b865ce5c60f18d3d9bdaeb1faa6ee499910f6f51b733c41c24" => :high_sierra
    sha256 "2ecc489904cfa0804a8828e45ff353345ac7a3595c8fc8023196ff37524d5215" => :x86_64_linux
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "gettext"
  depends_on "libffi"
  depends_on "pcre"
  depends_on "python@3.8"

  depends_on "util-linux" unless OS.mac? # for libmount.so

  # https://bugzilla.gnome.org/show_bug.cgi?id=673135 Resolved as wontfix,
  # but needed to fix an assumption about the location of the d-bus machine
  # id file.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/formula-patches/6164294a75541c278f3863b111791376caa3ad26/glib/hardcoded-paths.diff"
    sha256 "a57fec9e85758896ff5ec1ad483050651b59b7b77e0217459ea650704b7d422b"
  end

  def install
    Language::Python.rewrite_python_shebang(Formula["python@3.8"].opt_bin/"python3")

    inreplace %w[gio/gdbusprivate.c gio/xdgmime/xdgmime.c glib/gutils.c],
      "@@HOMEBREW_PREFIX@@", HOMEBREW_PREFIX

    # Disable dtrace; see https://trac.macports.org/ticket/30413
    args = std_meson_args + %W[
      -Diconv=auto
      -Dgio_module_dir=#{HOMEBREW_PREFIX}/lib/gio/modules
      -Dbsymbolic_functions=false
      -Ddtrace=false
    ]

    args << "-Diconv=native" if OS.mac?
    # Prevent meson to use lib64 on centos
    args << "--libdir=#{lib}" unless OS.mac?

    mkdir "build" do
      system "meson", *args, ".."
      system "ninja", "-v"
      # Some files have been generated with a Python shebang, rewrite these too
      Language::Python.rewrite_python_shebang(Formula["python@3.8"].opt_bin/"python3")
      system "ninja", "install", "-v"
    end

    # ensure giomoduledir contains prefix, as this pkgconfig variable will be
    # used by glib-networking and glib-openssl to determine where to install
    # their modules
    inreplace lib/"pkgconfig/gio-2.0.pc",
              "giomoduledir=#{HOMEBREW_PREFIX}/lib/gio/modules",
              "giomoduledir=${libdir}/gio/modules"

    # `pkg-config --libs glib-2.0` includes -lintl, and gettext itself does not
    # have a pkgconfig file, so we add gettext lib and include paths here.
    gettext = Formula["gettext"].opt_prefix
    lintl = OS.mac? ? " -lintl": ""
    inreplace lib+"pkgconfig/glib-2.0.pc" do |s|
      s.gsub! "Libs:#{lintl} -L${libdir} -lglib-2.0",
              "Libs: -L${libdir} -lglib-2.0 -L#{gettext}/lib#{lintl}"
      s.gsub! "Cflags:-I${includedir}/glib-2.0 -I${libdir}/glib-2.0/include",
              "Cflags:-I${includedir}/glib-2.0 -I${libdir}/glib-2.0/include -I#{gettext}/include"
    end

    # `pkg-config --print-requires-private gobject-2.0` includes libffi,
    # but that package is keg-only so it needs to look for the pkgconfig file
    # in libffi's opt path.
    libffi = Formula["libffi"].opt_prefix
    inreplace lib+"pkgconfig/gobject-2.0.pc" do |s|
      s.gsub! "Requires.private: libffi",
              "Requires.private: #{libffi}/lib/pkgconfig/libffi.pc"
    end

    bash_completion.install Dir["gio/completion/*"]
  end

  def post_install
    (HOMEBREW_PREFIX/"lib/gio/modules").mkpath
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <string.h>
      #include <glib.h>

      int main(void)
      {
          gchar *result_1, *result_2;
          char *str = "string";

          result_1 = g_convert(str, strlen(str), "ASCII", "UTF-8", NULL, NULL, NULL);
          result_2 = g_convert(result_1, strlen(result_1), "UTF-8", "ASCII", NULL, NULL, NULL);

          return (strcmp(str, result_2) == 0) ? 0 : 1;
      }
    EOS
    system ENV.cc, "-o", "test", "test.c", "-I#{include}/glib-2.0",
                   "-I#{lib}/glib-2.0/include", "-L#{lib}", "-lglib-2.0"
    system "./test"
  end
end
