require "./spec_helper"

TMP_DIR = File.join("spec", "tmp")

describe FileWatcher do
  around_each do |example|
    FileUtils.rm_rf(TMP_DIR)

    with_timeout(1.second) do
      example.run
    end
  rescue TimeoutError
    test = example.example
    raise TimeoutError.new(%Q(Timeout error on #{test.file}:#{test.line} - #{test.description}"))
  ensure
    FileUtils.rm_rf(TMP_DIR)
  end

  it "notifies added files" do
    spawn do
      create_file(File.join(TMP_DIR, "example.txt"))
    end

    pattern : String = Path[TMP_DIR, "**", "*"].to_posix.to_s

    FileWatcher.watch(pattern, interval: 0.01.seconds) do |event|
      event.type.added?.should be_true
      event.path.should eq File.join(TMP_DIR, "example.txt")
      break
    end
  end

  it "notifies removed files" do
    create_file(File.join(TMP_DIR, "example.txt"))

    spawn do
      File.delete(File.join(TMP_DIR, "example.txt"))
    end

    pattern : String = Path[TMP_DIR, "**", "*"].to_posix.to_s

    FileWatcher.watch(pattern, interval: 0.01.seconds) do |event|
      event.type.deleted?.should be_true
      event.path.should eq File.join(TMP_DIR, "example.txt")
      break
    end
  end

  it "notifies changed files" do
    create_file(File.join(TMP_DIR, "example.txt"))

    spawn do
      FileUtils.touch(File.join(TMP_DIR, "example.txt"))
    end

    pattern : String = Path[TMP_DIR, "**", "*"].to_posix.to_s

    FileWatcher.watch(pattern, interval: 0.01.seconds) do |event|
      event.type.changed?.should be_true
      event.path.should eq File.join(TMP_DIR, "example.txt")
      break
    end
  end

  it "respects given pattern" do
    spawn do
      create_file(File.join(TMP_DIR, "code.cr"))
      create_file(File.join(TMP_DIR, "data.json"))
      create_file(File.join(TMP_DIR, "text.txt"))
    end

    pattern : String = Path[TMP_DIR, "**", "*.json"].to_posix.to_s

    FileWatcher.watch(pattern, interval: 0.01.seconds) do |event|
      event.type.added?.should be_true
      event.path.should eq File.join(TMP_DIR, "data.json")
      break
    end
  end

  it "accepts Path pattern" do
    spawn do
      create_file(File.join(TMP_DIR, "example.txt"))
    end

    pattern : Path = Path[TMP_DIR, "**", "*"].to_posix

    FileWatcher.watch(pattern, interval: 0.01.seconds) do |event|
      event.type.added?.should be_true
      event.path.should eq File.join(TMP_DIR, "example.txt")
      break
    end
  end

  it "accepts multiples patterns" do
    spawn do
      create_file(File.join(TMP_DIR, "folder_a", "foo.txt"))
      create_file(File.join(TMP_DIR, "folder_b", "bar.txt"))
    end

    events = [] of FileWatcher::Event

    pattern_a : Path = Path[TMP_DIR, "folder_a", "*.txt"].to_posix
    pattern_b : String = Path[TMP_DIR, "folder_b", "*.txt"].to_posix.to_s

    FileWatcher.watch(pattern_a, pattern_b, interval: 0.01.seconds) do |event|
      events << event

      break if events.size == 2
    end

    events.should contain FileWatcher::Event.new(File.join(TMP_DIR, "folder_a", "foo.txt"), :added)
    events.should contain FileWatcher::Event.new(File.join(TMP_DIR, "folder_b", "bar.txt"), :added)
  end

  it "accepts match_option" do
    spawn do
      create_file(File.join(TMP_DIR, ".dotfile"))
    end

    pattern : String = Path[TMP_DIR, "**", "*"].to_posix.to_s

    FileWatcher.watch(pattern, interval: 0.01.seconds, match_option: File::MatchOptions::DotFiles) do |event|
      event.type.added?.should be_true
      event.path.should eq File.join(TMP_DIR, ".dotfile")
      break
    end
  end

  it "allows following symlinks" do
    FileUtils.mkdir_p(File.join(TMP_DIR, "original"))

    FileUtils.cd(TMP_DIR) do
      FileUtils.ln_s("original", "symlink")
    end

    spawn do
      create_file(File.join(TMP_DIR, "original", "example.txt"))
    end

    pattern : String = Path[TMP_DIR, "**", "*.txt"].to_posix.to_s

    FileWatcher.watch(pattern, interval: 0.01.seconds, follow_symlinks: true) do |event|
      # ignores if original file event is emitted first
      next if event.path == File.join(TMP_DIR, "original", "example.txt")

      event.type.added?.should be_true
      event.path.should eq File.join(TMP_DIR, "symlink", "example.txt")
      break
    end
  end

  it "allows customising polling interval" do
    spawn do
      create_file(File.join(TMP_DIR, "example.txt"))
    end

    pattern : String = Path[TMP_DIR, "**", "*"].to_posix.to_s

    started_at = Time.utc

    FileWatcher.watch(pattern, interval: 0.5.seconds) do |event|
      event.type.added?.should be_true
      event.path.should eq File.join(TMP_DIR, "example.txt")

      now = Time.utc
      now.should be_close(started_at + 0.5.seconds, 0.1.seconds)

      break
    end
  end
end
