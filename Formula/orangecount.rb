# OrangeCount — a single-binary beancount v3 engine with a bidirectional
# Chinese-friendly dialect, a Fava-compatible web UI, and read-only query CLI.
# Binary-only formula: each platform downloads its prebuilt static binary
# from the GitHub release (zero runtime dependencies, pure Go).
class Orangecount < Formula
  desc "Beancount v3 engine with dialect superset, Fava-compatible UI and query CLI"
  homepage "https://github.com/woyin/orangecount"
  url "https://github.com/woyin/orangecount/releases/download/v0.3.0/orangecount-darwin-arm64"
  version "0.3.0"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/woyin/orangecount/releases/download/v0.3.0/orangecount-darwin-arm64"
      sha256 "2cbb4f1bb7f565baa440c70baa9523fd1568bc19802813d8e2b63e2f678ecf52"
    end
    on_intel do
      url "https://github.com/woyin/orangecount/releases/download/v0.3.0/orangecount-darwin-amd64"
      sha256 "8cf0921a206b3fca6e2054efd1c679f2f12ea6c2ea1f3b14447b41bf6069f040"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/woyin/orangecount/releases/download/v0.3.0/orangecount-linux-arm64"
      sha256 "ddc694bce5a4a65b77ebce0865ecf9db47d59eeece647354a62133567783485a"
    end
    on_intel do
      url "https://github.com/woyin/orangecount/releases/download/v0.3.0/orangecount-linux-amd64"
      sha256 "c313802fd5c5aac822a225b475db2052d7f1b41146429956b7515b621de05a9b"
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
