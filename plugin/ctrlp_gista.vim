if exists('s:loaded_ctrlp_gista')
  finish
endif
let s:loaded_ctrlp_gista = 1
let s:save_cpo = &cpo
set cpo&vim

command! -nargs=?
      \ CtrlPGista
      \ call ctrlp#init(ctrlp#gista#cmd(<q-args>))

let &cpo = s:save_cpo
unlet s:save_cpo
