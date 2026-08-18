# OrangeCount — a single-binary beancount v3 engine with a bidirectional
# Chinese-friendly dialect, a Fava-compatible web UI, and read-only query CLI.
# Binary-only formula: each platform downloads its prebuilt static binary
# from the GitHub release (zero runtime dependencies, pure Go).
class Orangecount < Formula
  desc "Beancount v3 engine with dialect superset, Fava-compatible UI and query CLI"
  homepage "https://github.com/woyin/orangecount"
  url "https://github.com/woyin/orangecount/releases/download/v0.2.0/orangecount-darwin-arm64"
  version "0.2.0"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/woyin/orangecount/releases/download/v0.2.0/orangecount-darwin-arm64"
      sha256 "9cb9f32e93cb5ef626a63dd1de47b8705da23c34f285cefa844e6b6b59bf05d4"
    end
    on_intel do
      url "https://github.com/woyin/orangecount/releases/download/v0.2.0/orangecount-darwin-amd64"
      sha256 "b1f5f64d54caaf6b2189a18b5b503bec78dcfb7e2da46a633c7e8a9a70b57c8b"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/woyin/orangecount/releases/download/v0.2.0/orangecount-linux-arm64"
      sha256 "0ab15659bdb4d98fd00de017fb64bf4bd63c617dff19966c5f62f4de9d698f34"
    end
    on_intel do
      url "https://github.com/woyin/orangecount/releases/download/v0.2.0/orangecount-linux-amd64"
      sha256 "3289869abca6c36b5a0d76d990493749ac8b98d2950e7d7fe3d960d6680626c1"
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
