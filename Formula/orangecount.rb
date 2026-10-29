# OrangeCount — a single-binary Beancount v3 superset engine with a
# Fava-compatible web UI, a BQL query CLI, and a localized account-root scheme.
# Binary-only formula: each platform downloads its prebuilt static binary from
# the GitHub release (zero runtime dependencies, pure Go).
class Orangecount < Formula
  desc "Beancount v3 superset engine with Fava-compatible UI and BQL query CLI"
  homepage "https://github.com/woyin/orangecount"
  version "0.3.9"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/woyin/orangecount/releases/download/v#{version}/orangecount-darwin-arm64"
      sha256 "db718c8ce2712c7bccb24f3d701b5f3bf2d43bb2305a75cae42497cadcb1afba"
    end
    on_intel do
      url "https://github.com/woyin/orangecount/releases/download/v#{version}/orangecount-darwin-amd64"
      sha256 "2a660c0bc535941ef013176d8462b12d7bf3b2591088ad7be1f55adb569a5c52"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/woyin/orangecount/releases/download/v#{version}/orangecount-linux-arm64"
      sha256 "d7fb77dd7729e9bb281fc4c099016100f919b4d6abec81e04e35a3c088f304d2"
    end
    on_intel do
      url "https://github.com/woyin/orangecount/releases/download/v#{version}/orangecount-linux-amd64"
      sha256 "227247a7dd20b0ed1085684b545346fc33e8f96c0d5023e4fde5340860e2ff99"
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

    # The localized root scheme is this line's headline feature.
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

    # 0.3.9 exports an include tree from a build without cgo, which is what a
    # released binary is. A silent refusal here shipped for three releases.
    (testpath/"book/main.bean").write <<~EOS
      include "accounts.bean"
    EOS
    (testpath/"book/accounts.bean").write <<~EOS
      option "operating_currency" "CNY"
      2026-01-01 open Assets:Wallet CNY
    EOS
    (testpath/"out").mkpath
    system bin/"orangecount", "export", "--semantics", "v3",
           "-out", testpath/"out/book", testpath/"book/main.bean"
    assert_path_exists testpath/"out/book/accounts.bean"
  end
end
