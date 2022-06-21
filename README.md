# lightnovel.sh

A terminal-based lightnovel reader written in Bash. It scrapes [freewebnovel](https://freewebnovel.com/)

## Table of Contents

* [Table of Contents](#table-of-contents)
* [Features](#features)
* [Installation](#installation)
  * [Linux](#linux)
* [Usage](#usage)
* [Credits](#credits)

## Features

- Read daily updated english translated novels, retrieved from [freewebnovel's](https://freewebnovel.com/) extensive library.
- Focused on simplicity, minimalism and usability.
- Written in Bash, with minimal dependencies and easily tweakable.
- Stores your 20 most recently read novels[^1] to continue reading where you left off.
- It uses the `less` pager by default, which can be changed by setting the `PAGER` environment variable.

[^1]: This can be easily changed by editing the `HISTORY_LENGHT` variable on the script.

## Installation

### Linux

#### Dependencies

Make sure you have these installed

```text
awk cat curl grep head less mkdir sed tput tr w3m
```

#### Installing

```sh
git clone https://github.com/lr-tech/lightnovel.sh && sudo cp lightnovel.sh/lightnovel.sh /usr/local/bin/lightnovel.sh
```

#### Uninstalling

```sh
sudo rm /usr/local/bin/lightnovel.sh
```

## Usage

```text
A terminal-based lightnovel reader written in Bash.

USAGE:
  lightnovel.sh [OPTION]

OPTIONS:
  -c, --clear-cache     Clear cache (/home/newman/.cache/lightnovel.sh)
  -h, --help            Print this help page
  -l, --last-session    Restore last session
  -V, --version         Print version number
```

## Credits

- [lightnovel-cli](https://github.com/Username-08/lightnovel-cli): A simple program to read lightnovels in your terminal (Written in Rust).
- [manga-cli](https://github.com/7USTIN/manga-cli): Bash script for reading mangas via the terminal.
