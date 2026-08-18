# OrangeCount — a single-binary beancount v3 engine with a bidirectional
# Chinese-friendly dialect, a Fava-compatible web UI, and read-only query CLI.
# Binary-only formula: each platform downloads its prebuilt static binary
# from the GitHub release (zero runtime dependencies, pure Go).
class Orangecount < Formula
  desc "Beancount v3 engine with dialect superset, Fava-compatible UI and query CLI"
  homepage "https://github.com/woyin/orangecount"
  url "https://github.com/woyin/orangecount/releases/download/v0.3.1/orangecount-darwin-arm64"
  version "0.3.1"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/woyin/orangecount/releases/download/v0.3.1/orangecount-darwin-arm64"
      sha256 "b4897fa600dce4f76ee605d12ae5d31b60354bddc091aa594cedf2eb7e42b3ce"
    end
    on_intel do
      url "https://github.com/woyin/orangecount/releases/download/v0.3.1/orangecount-darwin-amd64"
      sha256 "e525bcf86a27d956a51312596903c2b665f5b36dafbddc6ca7d3ee8ddd071150"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/woyin/orangecount/releases/download/v0.3.1/orangecount-linux-arm64"
      sha256 "de09515bfba87d02ccfd36e32a0d6ae626fb0d20e7c5d87a40ba27951c86466a"
    end
    on_intel do
      url "https://github.com/woyin/orangecount/releases/download/v0.3.1/orangecount-linux-amd64"
      sha256 "36c7d1167a74846fbde3915fbe6db97b08c4b7a0b1370fa73af056b590fddaaa"
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
