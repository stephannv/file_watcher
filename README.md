# FileWatcher

<a href="https://github.com/stephannv/file_watcher/actions/workflows/ci.yml"><img src="https://github.com/stephannv/file_watcher/actions/workflows/ci.yml/badge.svg" alt="Tests"></a>
![0 dependencies](https://img.shields.io/badge/0-dependencies-blue)

Listen to file modifications using polling and notifies you about the changes. Pure Crystal implementation, no dependencies.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     file_watcher:
       github: stephannv/file_watcher
   ```

2. Run `shards install`

## Usage

```crystal
require "file_watcher"
```

#### Basic usage

```crystal
FileWatcher.watch("/path/to/folder/**/*.txt") do |event|
  puts event.path # Path to file, eg. "path/to/folder/file.txt"
end
```

#### Multiple patterns

```crystal
FileWatcher.watch("/path/to/folder/**/*", "/other/folder/**/*") do |event|
  # do something
end
```

#### Event types

The `type` could be `FileWatcher::EventType::Added`, `FileWatcher::EventType::Changed` or `FileWatcher::EventType::Deleted`.

```crystal
FileWatcher.watch("/path/to/folder/**/*") do |event|
  event.type.added?
  event.type.changed?
  event.type.deleted?

  # using case
  case event.type
  in .added?
    # do something
  in .changed?
    # do something
  in .deleted?
    # do something
  end
end
```

#### Using Path instead of String

```crystal
FileWatcher.watch(Path["~path/to/folder/**/*"].expand(home: true)) do |event|
  # do something
end
```

#### Using File::MatchOptions

It allows to listen to hidden files, dot files, etc. The default value is `File::MatchOptions.glob_default`. Read more here: [https://crystal-lang.org/api/File/MatchOptions.html].

```crystal
FileWatcher.watch("/path/to/folder/**/*", match_options: File::MatchOptions::DotFiles) do |event|
  puts event.path # eg. "path/to/folder/.file"
end
```

#### Symlinks

You can listen to changes in symlinks using `follow_symlinks: true`.

```crystal
FileWatcher.watch("/path/to/folder/**/*", follow_symlinks: true) do |event|
  # do something
end
```

#### Poll interval

By default the interval between each check is 1 second, you can change it passing `interval: your_value`.

```crystal
FileWatcher.watch("/path/to/folder/**/*", interval: 0.10.seconds) do |event|
  # do something
end
```

## Development

- `crystal spec` to run tests.

## Contributing

1. Fork it (<https://github.com/stephannv/file_watcher/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [stephann](https://github.com/stephannv) - creator and maintainer
