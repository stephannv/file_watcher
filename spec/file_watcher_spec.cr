require "./spec_helper"

TMP_DIR = "spec/tmp"

describe FileWatcher do
  around_each do |example|
    FileUtils.rm_rf(TMP_DIR)

    with_timeout(2.second) do
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

    FileWatcher.watch(File.join(TMP_DIR, "**", "*"), interval: 0.01.seconds) do |event|
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

    FileWatcher.watch(File.join(TMP_DIR, "**", "*"), interval: 0.01.seconds) do |event|
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

    FileWatcher.watch(File.join(TMP_DIR, "**", "*"), interval: 0.01.seconds) do |event|
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

    FileWatcher.watch(File.join(TMP_DIR, "**", "*.json"), interval: 0.01.seconds) do |event|
      event.type.added?.should be_true
      event.path.should eq File.join(TMP_DIR, "data.json")
      break
    end
  end

  it "accepts Path pattern" do
    spawn do
      create_file(File.join(TMP_DIR, "example.txt"))
    end

    FileWatcher.watch(Path[TMP_DIR, "**", "*"], interval: 0.01.seconds) do |event|
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

    FileWatcher.watch(
      Path[TMP_DIR, "folder_a", "*.txt"],
      File.join(TMP_DIR, "folder_b/*.txt"),
      interval: 0.01.seconds
    ) do |event|
      events << event

      break if events.size == 2
    end

    events.should contain FileWatcher::Event.new(File.join(TMP_DIR, "folder_a/foo.txt"), :added)
    events.should contain FileWatcher::Event.new(File.join(TMP_DIR, "folder_b/bar.txt"), :added)
  end

  it "accepts match_option" do
    spawn do
      create_file(File.join(TMP_DIR, ".dotfile"))
    end

    FileWatcher.watch(
      Path[TMP_DIR, "**", "*"],
      interval: 0.01.seconds,
      match_option: File::MatchOptions::DotFiles
    ) do |event|
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
      create_file(File.join(TMP_DIR, "original/example.txt"))
    end

    FileWatcher.watch("spec/tmp/**/*.txt", interval: 0.01.seconds, follow_symlinks: true) do |event|
      event.type.added?.should be_true
      event.path.should eq File.join(TMP_DIR, "symlink/example.txt")
      break
    end
  end

  it "allows customising polling interval" do
    spawn do
      create_file(File.join(TMP_DIR, "example.txt"))
    end

    started_at = Time.utc

    FileWatcher.watch(File.join(TMP_DIR, "**", "*"), interval: 1.second) do |event|
      event.type.added?.should be_true
      event.path.should eq File.join(TMP_DIR, "example.txt")

      now = Time.utc
      now.should be_close(started_at + 1.second, 0.1.seconds)

      break
    end
  end
end
