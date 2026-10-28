# OrangeCount — a single-binary Beancount v3 reader/validator with a
# Fava-compatible web UI and a query CLI.
# Binary-only formula: each platform downloads its prebuilt static binary from
# the GitHub release (zero runtime dependencies, pure Go).
#
# Version note: this formula tracks the published GitHub release. The source
# repository's HEAD is a later generation that adds --semantics, typed query
# formats, compare-semantics and the localized account-root scheme; none of
# those flags exist in 0.3.7, so this test block only asserts what 0.3.7
# actually supports.
class Orangecount < Formula
  desc "Beancount v3 reader and validator with a Fava-compatible web UI"
  homepage "https://github.com/woyin/orangecount"
  version "0.3.7"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/woyin/orangecount/releases/download/v#{version}/orangecount-darwin-arm64"
      sha256 "8d674277d1a0c728cddf55004b42edf4903e50edc21e08d7ef0b48d21a973072"
    end
    on_intel do
      url "https://github.com/woyin/orangecount/releases/download/v#{version}/orangecount-darwin-amd64"
      sha256 "a9638cac2c906e156402e48bd26b0c1f2392ebfc6dbeaa4758a20daec1a5e99c"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/woyin/orangecount/releases/download/v#{version}/orangecount-linux-arm64"
      sha256 "fe5bdabd33f8a9983eedc3dd4c84e9766db438858ec8f106eebe7d9adfc53a64"
    end
    on_intel do
      url "https://github.com/woyin/orangecount/releases/download/v#{version}/orangecount-linux-amd64"
      sha256 "bcf131fcffd36d972e4603fba59611e58830ff6d0de9d97a37c3a257f8da821c"
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
      point it at. Start the web workbench with:
        orangecount serve --addr 127.0.0.1:5100 /path/to/main.bean

      This build predates the --semantics switch, so it validates every ledger
      with the legacy profile. To validate with Beancount v3 semantics, build
      the source repository's current HEAD instead:
        git clone https://github.com/woyin/orangecount && cd orangecount && make build
    EOS
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/orangecount version")

    (testpath/"smoke.bean").write <<~EOS
      option "operating_currency" "CNY"
      2026-01-01 open Assets:Wallet CNY
      2026-01-01 open Expenses:Living CNY

      2026-01-02 * "smoke" "记账"
        Assets:Wallet -50 CNY
        Expenses:Living 50 CNY
    EOS
    assert_equal "", shell_output("#{bin}/orangecount check #{testpath}/smoke.bean 2>&1")

    # An unbalanced transaction must be reported, not accepted.
    (testpath/"bad.bean").write <<~EOS
      option "operating_currency" "CNY"
      2026-01-01 open Assets:Wallet CNY
      2026-01-02 * "unbalanced"
        Assets:Wallet -50 CNY
    EOS
    assert_match "E-EVAL-UNBALANCED",
                 shell_output("#{bin}/orangecount check #{testpath}/bad.bean 2>&1", 1)

    # The query CLI is the scripting surface; keep it working end to end.
    assert_match "Assets:Wallet", shell_output(
      "#{bin}/orangecount query --format csv #{testpath}/smoke.bean " \
      "'SELECT account FROM accounts ORDER BY account' 2>&1",
    )

    # Localized root names are accepted by this build (no option needed).
    (testpath/"cn.bean").write <<~EOS
      option "operating_currency" "CNY"
      2026-01-01 open 资产:钱包 CNY
      2026-01-01 open 支出:餐饮 CNY

      2026-01-02 * "午饭"
        资产:钱包 -50 CNY
        支出:餐饮 50 CNY
    EOS
    assert_equal "", shell_output("#{bin}/orangecount check #{testpath}/cn.bean 2>&1")
  end
end
