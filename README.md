# vim-os-unittestr

`vim-os-unittestr` is a simple helper plugin for running tox unittest in
OpenStack projects.

Open a file in which unittests are defined, go to a unittest and run it
in command line mode.

```
:OsRunTest
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

## Configuration

You can define the environment specified with `-e` in tox, as a variable
`g:vim_os_unittestr_env`. The default value is `py38`.
Overwrite it in your `.vimrc`, or set it in command line mode. For
example, set the value to `debug` to run unittest with pdb. You also
need to insert `import pdb; pdb.set_trace()` in your code to enter pdb
in this case.

```
let g:vim_os_unittestr_env = "debug"
```

## License

MIT
