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
let s:unittestr_env = g:vim_os_unittestr_env

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

  " Get path of opened file.
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

"""
" Get abs path of untitest and a set of class and function from test path. For
" example,
" `tacker.tests.unit.common.test_config.ConfigurationTest.test_load_paste_app`
" is converted to
" [
"   '/opt/stack/tacker/tacker/tests/unit/common/test_config.py',
"   ['ConfigurationTest', 'test_load_paste_app']
" ]
function! s:get_test_file_path(...)
  " Need to convert `a.b.c` to `a/b/c` to split first, but I don't know why '.'
  " cannot be work as a separator...
  let l:target_path = substitute(a:1, '\.', '/', 'g')
  let l:target_path = split(l:target_path, '/')
  if len(l:target_path) < 2
    echo 'Error: It is not a test path.'
    return []
  endif

  " Find class and function names, get it as ['Class', 'function'].
  let l:ptn_cls = '^Test'  " match a class derived from UnitTest
  let l:ptn_func = '^test_'
  let l:name_cls_fun = []

  if len(matchlist(l:target_path[-2], l:ptn_cls)) != 0 && len(matchlist(l:target_path[-1], l:ptn_func)) != 0
    call add(l:name_cls_fun, l:target_path[-2])
    call add(l:name_cls_fun, l:target_path[-1])
    let l:file_path = l:target_path[0:-3]
  elseif len(matchlist(l:target_path[-2], l:ptn_cls)) != 0
    call add(l:name_cls_fun, l:target_path[-2])
    let l:file_path = l:target_path[0:-2]
  elseif len(matchlist(l:target_path[-1], l:ptn_cls)) != 0
    call add(l:name_cls_fun, l:target_path[-1])
    let l:file_path = l:target_path[0:-2]
  else
    let l:file_path = l:target_path
  endif

  " Find absolute path of a file of unittest to be opened, or directory
  " possibly.
  " To find the abs path, get path of current dir of opened file, then conbine
  " it with `l:file_path` and check if it exists. If not found, cut the last
  " element of this `l:opened_fdir` and try to check step by step until it's
  " hit.
  let l:opened_fdir= split(expand("%:p"), "/")[0:-2]

  for i in range(len(l:opened_fdir))
    let l:path = '/'.join(l:opened_fdir[0:-1-i], '/')
    let l:path = l:path.'/'.join(l:file_path, '/')

    if filereadable(l:path.'.py')
      return [l:path.'.py', l:name_cls_fun]
    elseif isdirectory(l:path)
      return [l:path, l:name_cls_fun]
    endif
  endfor

endfunction

"""
" Open test function.
function! s:Open_definition(...)
  if a:0 > 0  " A test path is given as an argument.
    let l:fpath = s:get_test_file_path(a:1)
  else  " No test path given, so get it from position cursor on with '<cWORD>'.
    let l:fpath = s:get_test_file_path(expand('<cWORD>'))
  endif

  " Open the file test defined in, and jump to the definition.
  execute 'new '.l:fpath[0]
  if len(l:fpath[1]) == 2
    call search('def '.l:fpath[1][1])
  elseif len(l:fpath[1]) == 1
    call search('class '.l:fpath[1][0])
  endif
endfunction

" Open another terminal on vim and show the result, or continue to run
" debugger if it's run as debugging mode.
function! s:Run_tox_test(...)
  if a:0 == 0
    let l:env = s:unittestr_env
  elseif a:1 == 'debug'
    let l:env = 'debug'
  elseif a:1 == 'debug-insert'
    " Insert importing pdb at current line.
    let l:cpos = getpos('.')
    call cursor(l:cpos[1] - 1, 0)
    execute ':normal o'.'import pdb; pdb.set_trace()'
    call cursor(l:cpos[1], 0)
    execute 'write'
    let l:env = 'debug'
  else
    let l:env = a:1
  endif
  call term_start(['tox', '-e', l:env, s:get_test_full_path()])
endfunction

" Shortcuts to lunch the feature.
command OsRunTest :call <SID>Run_tox_test()
command OsRunDebug :call <SID>Run_tox_test('debug')
command OsRunDebugI :call <SID>Run_tox_test('debug-insert')
command -nargs=1 OsRunTox :call <SID>Run_tox_test(<f-args>)

command -nargs=? OsOpenDefinition :call <SID>Open_definition(<f-args>)
