# OrangeCount — a single-binary Beancount v3 superset engine with a
# Fava-compatible web UI, a BQL query CLI, and a localized account-root scheme.
# Binary-only formula: each platform downloads its prebuilt static binary from
# the GitHub release (zero runtime dependencies, pure Go).
class Orangecount < Formula
  desc "Beancount v3 superset engine with Fava-compatible UI and BQL query CLI"
  homepage "https://github.com/woyin/orangecount"
  version "0.3.8"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/woyin/orangecount/releases/download/v#{version}/orangecount-darwin-arm64"
      sha256 "c3ef2fc6d5dc1511dc7a9100f2794364e7417a0a5eea27f4911139844b71149e"
    end
    on_intel do
      url "https://github.com/woyin/orangecount/releases/download/v#{version}/orangecount-darwin-amd64"
      sha256 "193de0b206f9a0d75d486d8c1b660b5381dc474e2a329990944d682e656e607d"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/woyin/orangecount/releases/download/v#{version}/orangecount-linux-arm64"
      sha256 "7f00bd7690af9354deecf353a4f58bb98e468d7d5dfa10a1acd647fd2d6745a6"
    end
    on_intel do
      url "https://github.com/woyin/orangecount/releases/download/v#{version}/orangecount-linux-amd64"
      sha256 "1a0a1c1b98cd2ec00d78855a681d66de7448116779af1a38b83c18de7dfeeb6e"
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
        orangecount serve --semantics v3 --addr 127.0.0.1:5100 /path/to/main.bean

      Pass --semantics v3 for a Beancount v3 ledger; the default profile is
      legacy. The user guide is docs/user-guide.md in the source repository.
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
    assert_equal "", shell_output("#{bin}/orangecount check --semantics v3 #{testpath}/smoke.bean 2>&1")

    # An unbalanced transaction is reported through the exit status.
    (testpath/"bad.bean").write <<~EOS
      option "operating_currency" "CNY"
      2026-01-01 open Assets:Wallet CNY
      2026-01-02 * "unbalanced"
        Assets:Wallet -50 CNY
    EOS
    assert_match "E-EVAL-UNBALANCED",
                 shell_output("#{bin}/orangecount check --semantics v3 #{testpath}/bad.bean 2>&1", 1)

    # A root outside the configured account types is rejected, not dropped.
    (testpath/"bad-root.bean").write <<~EOS
      option "operating_currency" "CNY"
      2026-01-01 open Acme:Cash CNY
    EOS
    assert_match "E-EVAL-ACCOUNT",
                 shell_output("#{bin}/orangecount check --semantics v3 #{testpath}/bad-root.bean 2>&1", 1)

    # The localized root scheme is this release's headline feature.
    (testpath/"cn.bean").write <<~EOS
      option "account_root_scheme" "zh-Hans"
      option "operating_currency" "CNY"
      2026-01-01 open 资产:钱包 CNY
      2026-01-01 open 支出:餐饮 CNY

      2026-01-02 * "午饭"
        资产:钱包 -50 CNY
        支出:餐饮 50 CNY
    EOS
    assert_equal "", shell_output("#{bin}/orangecount check --semantics v3 #{testpath}/cn.bean 2>&1")

    # The typed query format is the scripting surface.
    assert_match "资产:钱包", shell_output(
      "#{bin}/orangecount query --format typed-csv --semantics v3 " \
      "#{testpath}/cn.bean 'SELECT account FROM accounts ORDER BY account' 2>&1",
    )

    # compare-semantics reports both profiles as valid in one JSON document.
    comparison = shell_output("#{bin}/orangecount compare-semantics #{testpath}/smoke.bean 2>&1")
    assert_match "\"legacy\"", comparison
    assert_match "\"v3\"", comparison
  end
end
