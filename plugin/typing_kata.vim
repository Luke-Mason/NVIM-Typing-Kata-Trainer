" Plugin initialization for typing-kata
if exists('g:loaded_typing_kata')
  finish
endif
let g:loaded_typing_kata = 1

" Plugin will be loaded lazily when user calls :TypingKata or setup() in Lua
