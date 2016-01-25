if exists('s:loaded_ctrlp_gista')
  finish
endif
let s:loaded_ctrlp_gista = 1

let s:V = gista#vital()
let s:List = s:V.import('Data.List')
let s:String = s:V.import('Data.String')
let s:CACHE_FORCED   = 2

let s:opener = {
      \ 'e': 'edit',
      \ 'v': 'vsplit',
      \ 'h': 'split',
      \ 't': 'tabnew',
      \}
let s:gista_var = {
      \ 'init': 'ctrlp#gista#init()',
      \ 'accept': 'ctrlp#gista#accept',
      \ 'wipe': 'ctrlp#gista#wipe',
      \ 'lname': 'gista',
      \ 'sname': 'gista',
      \ 'type': 'line',
      \ 'nolim': 1,
      \}
let s:gista_options = {}
let g:ctrlp_builtins = ctrlp#getvar('g:ctrlp_builtins')
let g:ctrlp_ext_vars = add(get(g:, 'ctrlp_ext_vars', []), s:gista_var)


function! s:truncate(str, width) abort
  let suffix = strdisplaywidth(a:str) > a:width ? '...' : '   '
  return s:String.truncate(a:str, a:width - 4) . suffix
endfunction
function! s:format_entry(entry) abort
  let description = empty(a:entry.description)
        \ ? join(keys(a:entry.files), ', ')
        \ : a:entry.description
  let description = substitute(description, "[\r\n]", ' ', 'g')
  let candidates = []
  for filename in keys(a:entry.files)
    let bufname = gista#command#open#bufname({
          \ 'gistid': a:entry.id,
          \ 'filename': filename,
          \ 'cache': s:CACHE_FORCED,
          \ 'verbose': 0,
          \})
    call add(candidates, [bufname, description])
  endfor
  return candidates
endfunction
function! s:syntax(longest) abort
  if ctrlp#nosy()
    return
  endif
  highlight default link CtrlPGistaFileName Comment
  execute printf("syntax match CtrlPGistaFileName /.\\zs.\\{%d}\\ze\t/", a:longest)
endfunction
function! s:parse_ctrlp_args(args) abort
  " CtrlPGista
  " CtrlPGista LOOKUP
  " CtrlPGista LOOKUP:USERNAME
  " CtrlPGista LOOKUP:USERNAME:APINAME
  let args = split(a:args, ':')
  let options = {
        \ 'lookup':   get(args, 0, ''),
        \ 'username': get(args, 1, 0),
        \ 'apiname':  get(args, 2, ''),
        \}
  return options
endfunction

function! ctrlp#gista#init() abort
  let session = gista#client#session(s:gista_options)
  try
    if session.enter()
      let result = gista#command#list#call(s:gista_options)
    else
      return []
    endif
  finally
    call session.exit()
  endtry
  let candidates = map(copy(result.index.entries), 's:format_entry(v:val)')
  let candidates = s:List.flatten(candidates, 1)
  let longest = 0
  for [bufname, description] in candidates
    if strlen(bufname) > longest
      let longest = strlen(bufname)
    endif
  endfor
  let s:candidates = []
  let preformatted = printf("%%-%ds\t%%s", longest)
  for [bufname, description] in candidates
    call add(s:candidates, printf(preformatted, bufname, description))
  endfor
  call s:syntax(longest)
  return s:candidates
endfunction
function! ctrlp#gista#accept(mode, str) abort
  call ctrlp#exit()
  let filename = matchstr(a:str, '^[^ ]\+')
  execute printf('%s %s', s:opener[a:mode], filename)
endfunction
function! ctrlp#gista#wipe(entries) abort
  return empty(a:entries)
        \ ? []
        \ : filter(s:candidates, 'index(a:entries, v:val) == -1')
endfunction

let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)
function! ctrlp#gista#cmd(...) abort
  let s:gista_options = s:parse_ctrlp_args(get(a:000, 0, ''))
  return s:id
endfunction
