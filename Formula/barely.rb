# Written by Barely's release build; any edit here is replaced by the next release.
class Barely < Formula
  desc "Memory friendly container manager for Docker"
  homepage "https://barely.dev"
  url "https://releases.barely.dev/2026.11.07-d4147b7/barely-2026.11.07-d4147b7-darwin-arm64.tar.gz"
  # Set here because Homebrew can't work out the version from the file name.
  version "2026.11.07-d4147b7"
  sha256 "dae50364dbd58a161fb813c47f5c05123572abb499c7cc40d91a6823cf456217"

  # The docker command and its compose and buildx plugins, which talk to the
  # Docker engine in Barely's VM. Homebrew keeps them in its own folder, so
  # they don't clash with Docker Desktop's.
  depends_on arch: :arm64
  depends_on "docker"
  depends_on "docker-buildx"
  depends_on "docker-compose"
  depends_on macos: :sonoma

  # Three downloads, so Homebrew can fetch them at the same time: the barely
  # command, the Linux image the VM boots and the Mac app.
  resource "guest" do
    url "https://releases.barely.dev/2026.11.07-d4147b7/barely-guest-2026.11.07.1331.tar.gz"
    sha256 "cd87648ee4cc0fc9082c8c9062273bf941fd8d9bca9e1afac2cda472decefa2b"
  end

  resource "app" do
    url "https://releases.barely.dev/2026.11.07-d4147b7/barely-app-2026.11.07-d4147b7-darwin-arm64.tar.gz"
    sha256 "d29abe37e9dbdd03539507cd317df23af7b290284102357121af550220987d48"
  end

  def install
    bin.install "bin/barely"
    libexec.install Dir["libexec/*"]
    doc.install Dir["share/doc/barely/*"]
    man1.install "share/man/man1/barely.1"

    resource("guest").stage do
      (share/"barely/guest/2026.11.07.1331").install Dir["*"]
    end
    # barely setup copies Barely.app to ~/Applications, where Spotlight finds it.
    resource("app").stage do
      prefix.install "Barely.app"
    end

    # Signed again after installing, in case Homebrew changed a file and re-signed
    # it without its entitlements. barelyvm and the app need the hypervisor
    # entitlement to run the VM.
    system "codesign", "--sign", "-", "--force", bin/"barely"
    system "codesign", "--sign", "-", "--force", libexec/"libkrun.1.dylib"
    system "codesign", "--sign", "-", "--force",
           "--entitlements", libexec/"barely.entitlements", libexec/"barelyvm"
    system "codesign", "--sign", "-", "--force",
           "--entitlements", libexec/"barely.entitlements", prefix/"Barely.app"
  end
end
