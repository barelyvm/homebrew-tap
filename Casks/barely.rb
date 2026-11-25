# Written by Barely's release build; any edit here is replaced by the next release.
# A cask, not a formula: a cask puts Barely.app in /Applications, where
# Spotlight and Launchpad find it, and the app finishes the install when it is
# first opened. A formula can only write inside Homebrew's own folder.
cask "barely" do
  version "2026.11.25-91e73e8"
  sha256 "b64e3a5d239073beca08f5d9a2d984e33a1b6c3c207af28b539179bbd5c795d3"

  url "https://releases.barely.dev/2026.11.25-91e73e8/barely-app-2026.11.25-91e73e8-darwin-arm64.tar.gz"
  name "Barely"
  desc "Memory friendly container manager for Docker"
  homepage "https://barely.dev"

  # The docker command and its compose and buildx plugins, which talk to the
  # Docker engine in Barely's VM. Homebrew keeps them in its own folder, so
  # they don't clash with Docker Desktop's.
  depends_on arch: :arm64
  depends_on macos: :sonoma
  depends_on formula: ["docker", "docker-buildx", "docker-compose"]

  # The app carries barely itself (Contents/Resources/barely), as a cask
  # downloads one archive.
  app "app/Barely.app"
  binary "#{appdir}/Barely.app/Contents/Resources/barely/bin/barely"
  manpage "#{appdir}/Barely.app/Contents/Resources/barely/share/man/man1/barely.1"

  # Homebrew marks what a cask installs as downloaded from the internet, and
  # macOS refuses to open an app so marked unless Apple has notarised it,
  # which Barely isn't. Clearing the mark is what lets the app and the barely
  # command run, as they do from a formula, which is never marked.
  # Then barely setup wires barely in where it is installed: the launchd agent
  # that starts the engine on the first docker command, and the docker
  # context. It never writes your shell profile, which is yours. barely runs
  # from inside the app; nothing is copied out of it.
  # Homebrew runs these steps sandboxed, writing only to the paths each step
  # names, and with a throwaway HOME, which setup --no-load sets aside for the
  # account's own; it prints only the line naming the agent the next step
  # loads. launchd refuses to load an agent from inside the sandbox, so the
  # last step loads it outside, as root for your login session, which asks
  # for your password. If the /var/run/docker.sock link was on before an
  # upgrade, that root step makes it again: the sandboxed step can't ask for
  # a password, and barely never runs sudo where it can't ask properly.
  postflight_steps do
    run "/usr/bin/xattr", args: ["-dr", "com.apple.quarantine", "{{appdir}}/Barely.app"],
                          writable_paths: ["{{appdir}}/Barely.app"]
    run "{{appdir}}/Barely.app/Contents/Resources/barely/bin/barely", args: ["setup", "--no-load"],
                                                                     writable_paths: ["~/.barely", "~/Library/LaunchAgents", "~/.docker"],
                                                                     print_stdout: true
    run "{{appdir}}/Barely.app/Contents/Resources/barely/bin/barely", args: ["setup", "--load"], sudo: true
  end

  # Homebrew runs this on brew upgrade as well as brew uninstall: the engine
  # stops and barely is unwired, keeping your images, containers and volumes,
  # and on an upgrade the postflight above wires the new version in again.
  # barely remove records which Docker switches were on, and barely setup
  # puts them back. Neither touches your shell profile: a DOCKER_HOST line
  # you turned on stays through an upgrade.
  uninstall quit:   "dev.barely.desktop",
            script: {
              executable: "#{appdir}/Barely.app/Contents/Resources/barely/bin/barely",
              args:       ["remove", "--quiet"],
            }

  # The /var/run/docker.sock link, if it still points at barely. barely
  # remove leaves it: Homebrew runs the uninstall script in a process group
  # of its own, where a sudo can't turn the terminal's echo off, so the
  # password would show as it was typed and never be read. Homebrew removes
  # it here with its own sudo, which asks properly, and only when the link is
  # barely's; on an upgrade, the new version's setup --load makes it again.
  uninstall_postflight_steps do
    remove "/var/run/docker.sock", symlink_target_contains: "/.barely/docker.sock", sudo: :if_needed
  end

  # brew uninstall --zap: also the VM's disk, with every image, container and
  # volume, the licence and the settings.
  zap trash: [
    "~/.barely",
    "~/Library/Caches/dev.barely.desktop",
    "~/Library/HTTPStorages/dev.barely.desktop",
    "~/Library/Preferences/dev.barely.desktop.plist",
    "~/Library/Saved Application State/dev.barely.desktop.savedState",
  ]
end
