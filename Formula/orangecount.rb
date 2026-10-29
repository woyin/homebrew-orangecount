# OrangeCount — a single-binary Beancount v3 superset engine with a
# Fava-compatible web UI, a BQL query CLI, and a localized account-root scheme.
# Binary-only formula: each platform downloads its prebuilt static binary from
# the GitHub release (zero runtime dependencies, pure Go).
class Orangecount < Formula
  desc "Beancount v3 superset engine with Fava-compatible UI and BQL query CLI"
  homepage "https://github.com/woyin/orangecount"
  version "0.3.11"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/woyin/orangecount/releases/download/v#{version}/orangecount-darwin-arm64"
      sha256 "66c64f0f6b9b799aae9023fba0d905c1e2a21f7aafe50df2836a994d7fcd0f23"
    end
    on_intel do
      url "https://github.com/woyin/orangecount/releases/download/v#{version}/orangecount-darwin-amd64"
      sha256 "ee5cd516efed7c30e038104ddc84fe6787f668ba82d13a575e12ceb56916ac94"
    end
  end
  on_linux do
    on_arm do
      url "https://github.com/woyin/orangecount/releases/download/v#{version}/orangecount-linux-arm64"
      sha256 "f6d1ca11b926ba38c9df87c55635d3d7ec88343df18e5cdfc0cb62330721952a"
    end
    on_intel do
      url "https://github.com/woyin/orangecount/releases/download/v#{version}/orangecount-linux-amd64"
      sha256 "3f20f1c84680903ffc292cbfb84657dd508bd7fc443e865d9da839df78d04f7b"
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

    # An include tree publishes from a build without cgo, which is what a
    # released binary is. A silent refusal here shipped for three releases.
    # (0.3.9; kept as a regression guard for every later release.)
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
    # Replacing a file this tool published must not disturb a file it preserved,
    # and it must not create a new backup on every run.
    (testpath/"src").mkpath
    (testpath/"src/one.bean").write <<~EOS
      option "operating_currency" "CNY"
      2026-01-01 open Assets:Wallet CNY
    EOS
    keep = testpath/"out/single.bean.orangecount.bak"
    keep.write "preserved original"
    system bin/"orangecount", "export", "--semantics", "v3",
           "-out", testpath/"out/single.bean", testpath/"src/one.bean"
    system bin/"orangecount", "export", "--semantics", "v3",
           "-out", testpath/"out/single.bean", testpath/"src/one.bean"
    assert_equal "preserved original", keep.read
    assert_path_exists testpath/"out/single.bean.orangecount.published"
  end
end
