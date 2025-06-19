# boom

boom is a shell command launcher that uses a JSON configuration file to store and organize commands. You can set environment variables for commands, pipe `stdin` into them and use fzf-powered fuzzy search for quick access.

## Install

Before using `boom`, make sure the following tools are installed and available in your `PATH`

- [jq](https://github.com/jqlang/jq) (>= 1.5)
- [fzf](https://github.com/junegunn/fzf) (>= 0.16.8)

Download the latest [release](https://github.com/boenner/boom-dev/releases/latest) and make `boom` executable. Optionally add `boom` to your `PATH` for easier use.

## Usage

To quickly navigate all of your bookmarked commands just run

```bash
boom
```

and you can fuzzy-search through your commands with `fzf`.

### List commands

You can use `boom --list` to get a list of all commands. If you combine `--list` with `--group` and/or `--subgroup` only the commands from that group will be listed.

The listing shows

- the group (if set)
- the subgroup (if set)
- the `exec` part of the command (will be cut off after 50 characters)
- `(env)` indicates that environment variables are set
- `(stdin)` indicates that something will be piped into the command

### Execute commands

Execute a specific command by running

```bash
boom --exec COMMAND
```

If the command belongs to a group/subgroup, you need to set the group with `--group GROUP` and/or subgroup with `--subgroup SUBGROUP`

```bash
boom --exec "get users" --group "postgres" --subgroup "local"
```

### Debugging commands

Use the verbose option (`--verbose` or `-v`) to run boom with `set -x`. This is helpful when troubleshooting why a bookmarked command is not behaving as expected, as you can see exactly what commands are being run.

### Limitations

- When one of the `env` assignments fails (failing subshell for example), the `exec` command will be executed anyway
- Output of the command in `exec` can't be piped or captured
- Executed commands will not be added to the history file
- Commands in a pipeline continue executing even if early parts fail, but the exit code will reflect any failures (logical operators like `&&` or `||` will work as expected)

## Options

Default delimiter for filling `fzf` is `\u001F` (Information Separator One). Don't use this in commands or if you have to, change it through the `--delimiter` option.

|     Short     |         Long          | Description                         |
| :-----------: | :-------------------: | ----------------------------------- |
|     `-l`      |       `--list`        | list all commands                   |
| `-x COMMAND`  |   `--exec COMMAND`    | execute a command                   |
|   `-c PATH`   |    `--config PATH`    | file path to a custom configuration |
|   `-d CHAR`   |  `--delimiter CHAR`   | specify custom delimiter for fzf    |
|  `-g GROUP`   |    `--group GROUP`    | set the group                       |
| `-s SUBGROUP` | `--subgroup SUBGROUP` | set the subgroup                    |
|     `-h`      |       `--help`        | display this help and exit          |
|     `-v`      |      `--verbose`      | enable verbose mode                 |
|     `-V`      |      `--version`      | output version information and exit |

## Configuration

`boom` looks for a configuration file in `~/.boomconf.json` by default. You can specify an alternative path using the environment variable `$BOOMCONF` or the `--config` option.

Commands can be stored directly or in a group and/or subgroup

```json
"group": {
    "subgroup": {
        "foo": {
            "exec": "echo \"foo\""
        }
    },
    "bar": {
        "exec": "echo \"bar\""
    },
    "baz": {
        "exec": "echo \"baz\""
    }
}
```

`boom` validates the configuration file and checks for

- proper JSON formatting
- every command must have at least the `exec` key, `stdin` and `env` are optional
- only `exec`, `env` and `stdin` are allowed inside a command. Any other fields will cause an error
- empty groups will throw an error
- valid environment variable names in the `env` field

## Development

### Contributing

Contributions are welcome. Fork the repository, create a feature branch, make your changes and submit a pull request. Please add tests for new features and check that all tests pass. Thanks!

### Tests

Testing is done with

- [bats](https://github.com/bats-core/bats-core)
- [bats-support](https://github.com/bats-core/bats-support)
- [bats-assert](https://github.com/bats-core/bats-assert)

You can install all packages with `npm`

```bash
npm install --dev
```

Run tests with `bash` and `zsh` from the root folder of the project by executing `npm run tests`

```bash
bash
npm test
zsh
npm test
```

## License

This project is licensed under the GNU General Public License v3.0, see the [LICENSE](LICENSE) file for details.
