# vim-os-unittestr

`vim-os-unittestr` is a simple helper plugin for running tox unittest in
OpenStack projects.

Open a file in which unittests are defined, go to a unittest and run it
in command line mode for running it in `py38` environment.

```
:OsRunTest
```

If you want to debug the code from the point you put
`import pdb; pdb.set_trace()`, run it in the command line mode.

```
:OsRunDebug
```

It is configurable if you run `:OsRunTox` with an argument for giving an
environment. For example, it is equal to run tox in `py38`.

```
:OsRunTox py38
```

If your cursor is on a test class, but outside of a method, it runs
whole of methods defined in the class. Furthermore, it runs whole of
tests in a file if cursor is outside of a class.

## Install

For dependency, it's required to install
[tyru/current-func-info.vim](https://github.com/tyru/current-func-info.vim)
with.
Install using your favorite package manager. Here is an example of using
[vim-plug](https://github.com/junegunn/vim-plug).

```
Plug 'tyru/current-func-info.vim'
Plug 'yasufum/vim-os-unittestr'
```

## License

MIT
