# OrangeCount — a single-binary beancount v3 engine with a bidirectional
# Chinese-friendly dialect, a Fava-compatible web UI, and read-only query CLI.
# Binary-only formula: each platform downloads its prebuilt static binary
# from the GitHub release (zero runtime dependencies, pure Go).
class Orangecount < Formula
  desc "Beancount v3 engine with dialect superset, Fava-compatible UI and query CLI"
  homepage "https://github.com/woyin/orangecount"
  url "https://github.com/woyin/orangecount/releases/download/v0.3.2/orangecount-darwin-arm64"
  version "0.3.2"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/woyin/orangecount/releases/download/v0.3.2/orangecount-darwin-arm64"
      sha256 "6cff372efac1be08237eda61d786b048e4f2af6cf17c8f166090edef3b7783bf"
    end
    on_intel do
      url "https://github.com/woyin/orangecount/releases/download/v0.3.2/orangecount-darwin-amd64"
      sha256 "c3642dc331eda97d8b55b803478a336898ec900a3d0d522a16aff79583d73cf4"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/woyin/orangecount/releases/download/v0.3.2/orangecount-linux-arm64"
      sha256 "8bf8db7b0d9f20efa7241dce3a0a547e0fc7ffb661e6eab84415097cfbdb49f7"
    end
    on_intel do
      url "https://github.com/woyin/orangecount/releases/download/v0.3.2/orangecount-linux-amd64"
      sha256 "62181277c47ea0313492a5021323e743ccf4b2559ca4db7afff468a57ba9a5e9"
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
