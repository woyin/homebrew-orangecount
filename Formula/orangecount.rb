# OrangeCount — a single-binary beancount v3 engine with a bidirectional
# Chinese-friendly dialect, a Fava-compatible web UI, and read-only query CLI.
# Binary-only formula: each platform downloads its prebuilt static binary
# from the GitHub release (zero runtime dependencies, pure Go).
class Orangecount < Formula
  desc "Beancount v3 engine with dialect superset, Fava-compatible UI and query CLI"
  homepage "https://github.com/woyin/orangecount"
  url "https://github.com/woyin/orangecount/releases/download/v0.3.5/orangecount-darwin-arm64"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/woyin/orangecount/releases/download/v0.3.5/orangecount-darwin-arm64"
      sha256 "b1b6e0bb22a571885ca937726c896c46c6426b706b13bbceb381a37b3813fe15"
    end
    on_intel do
      url "https://github.com/woyin/orangecount/releases/download/v0.3.5/orangecount-darwin-amd64"
      sha256 "e08861e8ae616e351f2d5a27d530f3ff82689d1d826eb855963402cae09b37d6"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/woyin/orangecount/releases/download/v0.3.5/orangecount-linux-arm64"
      sha256 "d3e07f6e11cf18719569230df35f9dc6cc0e8795717e34a8461acd046b0ec43b"
    end
    on_intel do
      url "https://github.com/woyin/orangecount/releases/download/v0.3.5/orangecount-linux-amd64"
      sha256 "cf536c732f70c02965dafadb2cbd285dda100a6d70a1ce7c39d13bf5fd849021"
    end
  end

  def install
    os = OS.mac? ? "darwin" : "linux"
    arch = Hardware::CPU.intel? ? "amd64" : "arm64"
    bin.install "orangecount-#{os}-#{arch}" => "orangecount"
  end

  def caveats
    <<~EOS
      OrangeCount is a local tool: it reads and writes only the ledger you
      point it at. Start the web UI with:
        orangecount serve /path/to/main.bean
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/orangecount version")
    (testpath/"smoke.bean").write <<~EOS
      2026-01-01 open Assets:Wallet CNY
      2026-01-01 open Expenses:Living CNY
      option "operating_currency" "CNY"

      2026-01-02 * "smoke" "记账"
        Assets:Wallet -50 CNY
        Expenses:Living 50 CNY
    EOS
    assert_equal "", shell_output("#{bin}/orangecount check #{testpath}/smoke.bean 2>&1")
  end
end
