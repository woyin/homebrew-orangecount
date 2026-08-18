# OrangeCount — a single-binary beancount v3 engine with a bidirectional
# Chinese-friendly dialect, a Fava-compatible web UI, and read-only query CLI.
# Binary-only formula: each platform downloads its prebuilt static binary
# from the GitHub release (zero runtime dependencies, pure Go).
class Orangecount < Formula
  desc "Beancount v3 engine with dialect superset, Fava-compatible UI and query CLI"
  homepage "https://github.com/woyin/orangecount"
  url "https://github.com/woyin/orangecount/releases/download/v0.3.4/orangecount-darwin-arm64"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/woyin/orangecount/releases/download/v0.3.4/orangecount-darwin-arm64"
      sha256 "f1721d4ce12ecc4410907057be7c5eb0a7ba74244630bfacece640295547668b"
    end
    on_intel do
      url "https://github.com/woyin/orangecount/releases/download/v0.3.4/orangecount-darwin-amd64"
      sha256 "d7d114b0c66949dc5ddde40352a52b12a060ec4ec27067d22b6eef5e68346ec0"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/woyin/orangecount/releases/download/v0.3.4/orangecount-linux-arm64"
      sha256 "5a0d02f72c327f6205cc03e9a1478c5b4fc6871ffffe1558b0910dae35c15a03"
    end
    on_intel do
      url "https://github.com/woyin/orangecount/releases/download/v0.3.4/orangecount-linux-amd64"
      sha256 "f87a9d88c17cab59e17ee08e983c24ddbc92e68282a25bb4298032decd4f5e51"
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
