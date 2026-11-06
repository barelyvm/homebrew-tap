# Written by Barely's release build; any edit here is replaced by the next release.
class Barely < Formula
  desc "Memory friendly container manager for Docker"
  homepage "https://barely.dev"
  url "https://releases.barely.dev/2026.11.07-c6c5637/barely-2026.11.07-c6c5637-darwin-arm64.tar.gz"
  # Set here because Homebrew can't work out the version from the file name.
  version "2026.11.07-c6c5637"
  sha256 "e34cf3e87aab95d357f59bebdf088ea33a2b25d6f9464190e6ecd49678557a39"

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
    url "https://releases.barely.dev/2026.11.07-c6c5637/barely-guest-2026.11.06.1507.tar.gz"
    sha256 "e24c2cb9ea7c2f5668a76b3fd43b1181187fa597e6a1f1fba44c328234ae4437"
  end

  resource "app" do
    url "https://releases.barely.dev/2026.11.07-c6c5637/barely-app-2026.11.07-c6c5637-darwin-arm64.tar.gz"
    sha256 "08109d5608b1ec0dd8de2a109e0adcdc80a29b7732746d06bd1257a95a0a8bd3"
  end

  def install
    bin.install "bin/barely"
    libexec.install Dir["libexec/*"]
    doc.install Dir["share/doc/barely/*"]
    man1.install "share/man/man1/barely.1"

    resource("guest").stage do
      (share/"barely/guest/2026.11.06.1507").install Dir["*"]
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

  def caveats
    <<~EOS
      Finish the install, which also puts Barely.app in ~/Applications:
        barely setup
    EOS
  end
end
