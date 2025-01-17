class Uv < Formula
  desc "Extremely fast Python package installer and resolver, written in Rust"
  homepage "https://github.com/astral-sh/uv"
  url "https://github.com/astral-sh/uv/archive/refs/tags/0.1.18.tar.gz"
  sha256 "017eb173e513e1d4e1699b72f6af5be285f6c8667e8bf706af2f44480aa32cac"
  license any_of: ["Apache-2.0", "MIT"]
  head "https://github.com/astral-sh/uv.git", branch: "main"

  bottle do
    sha256 cellar: :any,                 arm64_sonoma:   "c1f7cbf301e97c46210d319d506f3d2e7d50a41a946d6e87c5292c5988db1e3a"
    sha256 cellar: :any,                 arm64_ventura:  "472cc94d4373017dbeafa22359aae949169857b912801460713609c7bc178cc5"
    sha256 cellar: :any,                 arm64_monterey: "a2edd9d3fc8f8825abd9b4e88533958776c3bb7d45e0eca65f2ae1febb727294"
    sha256 cellar: :any,                 sonoma:         "6711bcb1f89099ea89ccbe5a74c6cce333c176255c25da78c9cc9a12547e7dc6"
    sha256 cellar: :any,                 ventura:        "95e19afee1ad7f9d009a5c5a9fa2db6be88d5b0116c16dfacae4d99401aaf7d6"
    sha256 cellar: :any,                 monterey:       "65f4fa3d9bfaaae40230add5855afd84550ba7d7f18dae5e6243989aee0df546"
    sha256 cellar: :any_skip_relocation, x86_64_linux:   "d0ad3e98ebcfcb814fbccec81bc3b0f470ff18f095f52c7c66e8d1859318a372"
  end

  depends_on "pkg-config" => :build
  depends_on "rust" => :build
  depends_on "libgit2"
  depends_on "openssl@3"

  uses_from_macos "python" => :test

  def install
    ENV["LIBGIT2_NO_VENDOR"] = "1"

    # Ensure that the `openssl` crate picks up the intended library.
    ENV["OPENSSL_DIR"] = Formula["openssl@3"].opt_prefix
    ENV["OPENSSL_NO_VENDOR"] = "1"

    system "cargo", "install", "--no-default-features", *std_cargo_args(path: "crates/uv")
    generate_completions_from_executable(bin/"uv", "generate-shell-completion")
  end

  def check_binary_linkage(binary, library)
    binary.dynamically_linked_libraries.any? do |dll|
      next false unless dll.start_with?(HOMEBREW_PREFIX.to_s)

      File.realpath(dll) == File.realpath(library)
    end
  end

  test do
    (testpath/"requirements.in").write <<~EOS
      requests
    EOS

    compiled = shell_output("#{bin}/uv pip compile -q requirements.in")
    assert_match "This file was autogenerated by uv", compiled
    assert_match "# via requests", compiled

    [
      Formula["libgit2"].opt_lib/shared_library("libgit2"),
      Formula["openssl@3"].opt_lib/shared_library("libssl"),
      Formula["openssl@3"].opt_lib/shared_library("libcrypto"),
    ].each do |library|
      assert check_binary_linkage(bin/"uv", library),
             "No linkage with #{library.basename}! Cargo is likely using a vendored version."
    end
  end
end
