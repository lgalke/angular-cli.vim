" Added by lgalke 28/02/17 

function! Angular-cli#init() abort
  call CreateEditCommands()
  call CreateGenerateCommands()
  command! -nargs=* Ng call ExecuteNgCommand(<q-args>)
endfunction

" The remaining functions are just prefixed by angular-cli# and suffixed by
" abort. Hope I did not miss any call statement.

function! angular-cli#ExecuteNgCommand(args) abort
  if g:angular-cli_use_dispatch == 1
    let prefix = 'Dispatch '
  else 
    let prefix = '!'
  endif
  execute prefix . 'ng ' . a:args
endfunction

function! angular-cli#CreateEditCommands() abort
  let modes = 
        \[ ['E', 'edit'],
        \  ['S', 'split'],
        \  ['V', 'vsplit'],
        \  ['T', 'tabnew'] ]
  for mode in modes
    let elements_with_relation = 
          \[ ['Component', 'component.ts'],
          \  ['Module', 'module.ts'],
          \  ['Template', 'component.html'],
          \  ['Spec', 'spec.ts'],
          \  ['Stylesheet', 'component.' . g:angular-cli_stylesheet_format] ]
    for element in elements_with_relation
      silent execute 'command! -nargs=? -complete=customlist,' . element[0] .'Files ' . mode[0] . element[0] . ' call angular-cli#EditRelatedFile(<q-args>, "'. mode[1] .'", "' .element[1]. '")'
    endfor
    let elements_without_relation = 
        \[ 'Directive',
        \  'Service',
        \  'Pipe',
        \  'Ng' ]
    for elt in elements_without_relation
      silent execute 'command! -nargs=1 -complete=customlist,'. elt . 'Files ' mode[0] . elt . ' call angular-cli#EditFile(<f-args>, "' . mode[1] .'")'
    endfor
  endfor

  command! -nargs=? -complete=customlist,SpecFiles ESpec call angular-cli#EditSpecFile(<q-args>, 'edit')
  command! -nargs=? -complete=customlist,SpecFiles SSpec call angular-cli#EditSpecFile(<q-args>, 'split')
  command! -nargs=? -complete=customlist,SpecFiles VSpec call angular-cli#EditSpecFile(<q-args>, 'vsplit')
  command! -nargs=? -complete=customlist,SpecFiles TSpec call angular-cli#EditSpecFile(<q-args>, 'tabnew')
endfunction

function! angular-cli#CreateGenerateCommands() abort
  let elements = 
        \[ 'Component',
        \  'Template',
        \  'Module',
        \  'Directive',
        \  'Service',
        \  'Class',
        \  'Interface',
        \  'Enum' ]
  for element in elements
    silent execute 'command! -nargs=1 -bang G' . element . ' call angular-cli#Generate("'.tolower(element).'", <q-args>)'
  endfor
endfunction

function! angular-cli#CreateDestroyCommand() abort
  silent execute command! -nargs=1 -complete=customlist,NgFiles call angular-cli#DestroyElement(<f-args>)
endfunction

function! angular-cli#ComponentFiles(A,L,P) abort
  return Files('component.ts', a:A)
endfunction

function! angular-cli#ModuleFiles(A,L,P) abort
  return Files('module.ts', a:A)
endfunction

function! angular-cli#DirectiveFiles(A,L,P) abort
  return Files('directive.ts', a:A)
endfunction

function! angular-cli#TemplateFiles(A,L,P) abort
  return Files('html', a:A)
endfunction

function! angular-cli#ServiceFiles(A,L,P) abort
  return Files('service.ts', a:A)
endfunction

function! angular-cli#PipeFiles(A,L,P) abort
  return Files('pipe.ts', a:A)
endfunction

function! angular-cli#SpecFiles(A,L,P) abort
  return Files('spec.ts', a:A)
endfunction

function! angular-cli#NgFiles(A,L,P) abort
  return Files('ts', a:A)
endfunction

function! angular-cli#StylesheetFiles(A,L,P) abort
  return Files(g:angular-cli_stylesheet_format, a:A)
endfunction

function! angular-cli#DestroyElement(file) abort
  call angular-cli#ExecuteNgCommand('d ' . g:global_files[a:file])
endfunction

function! angular-cli#Generate(type, name) abort
  call angular-cli#ExecuteNgCommand('g ' . a:type . ' ' . a:name)
endfunction

function! angular-cli#Files(extension,A) abort
  let path = '.'
  if isdirectory("src")
    let path .= '/src/'
  endif
  if isdirectory("app")
    let path .= '/app/'
  endif
  let files = split(globpath(path, '**/*'. a:A .'*.' . a:extension), "\n")
  let idx = range(0, len(files)-1)
  let g:global_files = {}
  for i in idx
    let g:global_files[fnamemodify(files[i], ':t:r')] = files[i]
  endfor
  call map(files, 'fnamemodify(v:val, ":t:r")')
  return files
endfunction

function! angular-cli#EditFile(file, command) abort
  let fileToEdit = has_key(g:global_files, a:file)?  g:global_files[a:file] : a:file . '.ts'
  if !empty(glob(fileToEdit))
    execute a:command fileToEdit
  else
    echoerr fileToEdit . ' was not found'
  endif
endfunction

function! angular-cli#EditFileIfExist(file, command, extension) abort
  let fileToEdit = exists('g:global_files') && has_key(g:global_files, a:file)?  g:global_files[a:file] : a:file
  if !empty(glob(fileToEdit))
    execute a:command fileToEdit
  else
    echoerr fileToEdit . ' was not found'
  endif
endfunction

function! angular-cli#EditSpecFile(file, command) abort
  let file = a:file
  if file == ''
    let file = substitute(expand('%'), '.ts', '.spec', '')
  endif 
    call angular-cli#EditFile(file, a:command)
endfunction

function! angular-cli#EditRelatedFile(file, command, target_extension) abort
  let file = a:file
  if file == ''
    let source_extension = GetSourceNgExtension()
    let file = substitute(expand('%'), source_extension,  '.' . a:target_extension, '')
    call angular-cli#EditFileIfExist(file, a:command, a:target_extension)
  else 
    call angular-cli#EditFileIfExist(a:file, a:command, a:target_extension)
  endif
endfunction

function! angular-cli#GetSourceNgExtension() abort
  let extensions = 
        \[ 'component.ts',
        \  'module.ts',
        \  'component.html',
        \  'component.' . g:angular-cli_stylesheet_format,
        \  'component.spec']
  for extension in extensions
    if expand('%e') =~ extension
      return '.' . extension
    endif
  endfor
  return '\.' . expand('%:e')
endfunction
