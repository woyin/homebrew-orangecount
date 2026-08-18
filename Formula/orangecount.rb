# OrangeCount — a single-binary beancount v3 engine with a bidirectional
# Chinese-friendly dialect, a Fava-compatible web UI, and read-only query CLI.
# Binary-only formula: each platform downloads its prebuilt static binary
# from the GitHub release (zero runtime dependencies, pure Go).
class Orangecount < Formula
  desc "Beancount v3 engine with dialect superset, Fava-compatible UI and query CLI"
  homepage "https://github.com/woyin/orangecount"
  url "https://github.com/woyin/orangecount/releases/download/v0.3.3/orangecount-darwin-arm64"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/woyin/orangecount/releases/download/v0.3.3/orangecount-darwin-arm64"
      sha256 "69c77087c200b9b40490a9b4d11ac816149054b0692f354b68e6344d5aa98768"
    end
    on_intel do
      url "https://github.com/woyin/orangecount/releases/download/v0.3.3/orangecount-darwin-amd64"
      sha256 "6e543fad1a824019765f05341a468993dc0c5629519980fb2ac739d0e4625d67"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/woyin/orangecount/releases/download/v0.3.3/orangecount-linux-arm64"
      sha256 "ad867298222fc267c0faf89d132c74ef74fe9d4c0377914b17f59f8523d30cef"
    end
    on_intel do
      url "https://github.com/woyin/orangecount/releases/download/v0.3.3/orangecount-linux-amd64"
      sha256 "3ea77f2e17bf82200635b69ca7d5b7f83a052ddcad5a544ca51548e934e60489"
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
