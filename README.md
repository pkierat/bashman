# Bashman

Bashman is a command-line interpreter of Postman collections. It parses JSON
files of collections and environments, converts them to Bash and runs using
curl.

## Prerequisites

* [bash 4+](https://www.gnu.org/software/bash/)
* [curl](https://curl.se/)
* [jq](https://github.com/jqlang/jq)
* [fzf](https://github.com/junegunn/fzf)

## Install

1. Clone the repository
2. Set and export the `BASHMAN_PATH` environment variable:
   ```
   export BASHMAN_PATH=path/to/postman/collections[:...]
   ```

## Run

```
$ cd bashman
$ ./bashman.sh
```

## Use

1. Load a proper environment:
   ```
   [env]:[col]:[item]:[code]> env ~/projects/pet-shop/postman/localhost.postman_environment.json
   localhost:[col]:[item]:[code]>
   ```
2. Load a collection:
   ```
   localhost:[col]:[item]:[code]> load ~/pet-shop/postman/pet-shop.postman_collection.json
   localhost:pet-shop:[item]:[code]>
   ```
3. Choose an item:
   ```
   localhost:pet-shop:[item]:[code]> item get_parrots_by_color
   localhost:pet-shop:get_parrots_by_color:[code]>
   ```
4. Make a call:
   ```
   localhost:pet-shop:get_parrots_by_color:[code]> run -v
   [{...},{...}, ...]
   localhost:pet-shop:get_parrots_by_color:[200]>
   ```

## Hints

* Bashman supports tab completion of commands, environments, collections and
  items (using `fzf`). This, however, will only work if the `BASHMAN_PATH`
   variable is set properly.
* Options passed to `run` are added to the actual `curl` command invocation,
  allowing for an _ad hoc_ modification of the request.
