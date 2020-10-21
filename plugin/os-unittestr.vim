" vim-os-unittestr

" A helper plugin for OpenStack for running unittests via tox. You can run a
" unit test where cursor is on a method starts with `test_`, or a set of
" tests if cursor is not on a specific method but a specific class. You can
" also run whole of tests if cursor is on other than specific class.

" Usage: Move cursor on a method, class or other than class to run the test(s)
" you define. Then, run `:OsRunTest`, `:OsRunDebug` or `:OsRunTox` in command
" line mode.
"
" You can specify an environment of the test, such as `py38`, `debug` or so,
" as a global variable `g:vim_os_unittestr_env` in your `.vimrc`. The default
" value is `py38`. So, no need to define it explicitly if you prefer to use
" the default value.

" Skip loading again if it's already loaded.
if exists("g:loaded_vim_os_unittestr")
  finish
endif
let g:loaded_vim_os_unittestr = 1

" Check dependency first, and terminate if it's not satistified.
" It depends on only one plugin currently.
let s:my_plugin = 'yasufum/vim-os-unittestr'
let s:required_plugin = 'tyru/current-func-info.vim'
if !exists('g:loaded_cfi')
    echo "Error: vim plugin '".s:required_plugin.
                \"' is requied for '".s:my_plugin."'!"
    finish
endif

" Set default tox env specified with `-e`. It can be overwritten in your
" `.vimrc`.
if !exists("g:vim_os_unittestr_env")
  let g:vim_os_unittestr_env = "py38"
endif

" Get class and function on cursor in a file you open as a list. For example,
" if cursor is on `TestMyCls.my_method`, it returns a list
" ['TestMyCls', 'my_method'].
" This function expects the class starts with `Test` and the function `test_`
function! s:get_func_name()
  let l:res = []

  let l:func_name = cfi#format("%s", "")

  " Termiinate if it's not in a class or function.
  if len(l:func_name) == 0
    return l:res
  endif

  let l:elems = split(l:func_name, '\.')
  let l:ptn_cls = 'Test'  " match a class derived from UnitTest
  let l:ptn_func = '^test_'

  " Check if it's in a test class or its function
  if len(matchlist(l:elems[0], l:ptn_cls)) == 0
    "echo join(["'", l:elems[0], "' is not a test class"], '')
  elseif len(matchlist(l:elems[1], l:ptn_func)) == 0
    call add(l:res, l:elems[0])
    "echo join(["'", l:elems[1], "' is not a test method"], '')
  else
    call add(l:res, l:elems[0])
    call add(l:res, l:elems[1])
  endif

  return l:res
endfunction

" Get the full path of unit test for giving tox command such as
" 'tacker.tests.unit.nfvo.test_nfvo_plugin.TestNfvoPlugin.test_create_vim'.
function! s:get_test_full_path()
  let l:res = []

  let l:full_path = split(expand("%:p"), "/")

  for i in range(len(l:full_path))
    let idx = len(l:full_path) - 1 - i

    " Find where the root of unittest.
    if l:full_path[idx-1] == "tests" && l:full_path[idx] == "unit"
      break
    endif

    if idx-1 == 0
      break
    endif
  endfor

  if idx != 0
    let t_root_idx = idx-2
    let f_dir_idx = len(l:full_path)-2
    let l:res = l:full_path[t_root_idx:f_dir_idx]
    call add(l:res, split(expand("%:r"), '/')[-1])

  endif

  for ent in s:get_func_name()
    call add(l:res, ent)
  endfor

  return join(l:res, '.')
endfunction

" Open another terminal on vim and show the result, or continue to run
" debugger if it's run as debugging mode.
function! s:Run_tox_test(...)
  if a:0 == 0
    let g:vim_os_unittestr_env = 'py38'
  elseif a:1 == 'debug'
    let g:vim_os_unittestr_env = 'debug'
  else
    let g:vim_os_unittestr_env = a:1
  endif
  call term_start(['tox', '-e', g:vim_os_unittestr_env, s:get_test_full_path()])
endfunction

" Shortuct to lunch the feature, named `RunTox` currently.
command OsRunTest :call <SID>Run_tox_test()
command OsRunDebug :call <SID>Run_tox_test('debug')
command -nargs=1 OsRunTox :call <SID>Run_tox_test(<f-args>)
