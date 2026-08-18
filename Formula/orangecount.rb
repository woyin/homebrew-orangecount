# OrangeCount — a single-binary beancount v3 engine with a bidirectional
# Chinese-friendly dialect, a Fava-compatible web UI, and read-only query CLI.
# Binary-only formula: each platform downloads its prebuilt static binary
# from the GitHub release (zero runtime dependencies, pure Go).
class Orangecount < Formula
  desc "Beancount v3 engine with dialect superset, Fava-compatible UI and query CLI"
  homepage "https://github.com/woyin/orangecount"
  url "https://github.com/woyin/orangecount/releases/download/v0.2.1/orangecount-darwin-arm64"
  version "0.2.1"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/woyin/orangecount/releases/download/v0.2.1/orangecount-darwin-arm64"
      sha256 "6044f2932e912c9c9d8957457a9a08d2846aee2ca3de80e0d302bee0646eb8a3"
    end
    on_intel do
      url "https://github.com/woyin/orangecount/releases/download/v0.2.1/orangecount-darwin-amd64"
      sha256 "2c70eedccddcdf962c909e5c67cbd110cd740d51c740aaa321781d40c2630f69"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/woyin/orangecount/releases/download/v0.2.1/orangecount-linux-arm64"
      sha256 "21d3f09b5d3487eb915968ae912a4ebf9e8d4e0d414dda9728e5e9ee25802067"
    end
    on_intel do
      url "https://github.com/woyin/orangecount/releases/download/v0.2.1/orangecount-linux-amd64"
      sha256 "6229cd287a9f466269d64d7f971ba2581744899b3b1a8f9699aa0700c38c30b5"
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
