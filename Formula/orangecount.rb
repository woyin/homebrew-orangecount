# OrangeCount — a single-binary beancount v3 engine with a bidirectional
# Chinese-friendly dialect, a Fava-compatible web UI, and read-only query CLI.
# Binary-only formula: each platform downloads its prebuilt static binary
# from the GitHub release (zero runtime dependencies, pure Go).
class Orangecount < Formula
  desc "Beancount v3 engine with dialect superset, Fava-compatible UI and query CLI"
  homepage "https://github.com/woyin/orangecount"
  url "https://github.com/woyin/orangecount/releases/download/v0.3.6/orangecount-darwin-arm64"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/woyin/orangecount/releases/download/v0.3.6/orangecount-darwin-arm64"
      sha256 "d9ca1729c19799207caf11624ae11d24faf129ea37421cfd556feeb0d231b72f"
    end
    on_intel do
      url "https://github.com/woyin/orangecount/releases/download/v0.3.6/orangecount-darwin-amd64"
      sha256 "8a9f18968a16b66132975e8106b314ad57510280e0ca541f8e5ea724c0825312"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/woyin/orangecount/releases/download/v0.3.6/orangecount-linux-arm64"
      sha256 "86962766433ee75a54285c6a7e58e1d90cc200fb8044ec171a0a6100244bde8a"
    end
    on_intel do
      url "https://github.com/woyin/orangecount/releases/download/v0.3.6/orangecount-linux-amd64"
      sha256 "5b55ab14acf9cc9462b4f5956a7d9c036db3538953c04101ae35530876203c91"
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
